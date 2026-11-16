#!/usr/bin/env bash
set -euo pipefail

# Grant this runner SSH access for the duration of a workflow run.
# Only a rule created by this invocation may be revoked.
: "${EC2_SECURITY_GROUP_ID:?Security group ID is required}"
[[ "$EC2_SECURITY_GROUP_ID" =~ ^sg-[0-9a-f]{8}([0-9a-f]{9})?$ ]]
command -v aws >/dev/null
python_bin=${PYTHON_BIN:-python3}
export AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1 AWS_PAGER= AWS_MAX_ATTEMPTS=2
aws() { command aws --region us-east-1 --no-cli-pager --cli-connect-timeout 10 --cli-read-timeout 30 "$@"; }
account=$(aws sts get-caller-identity --query Account --output text)
[[ "$account" == 109347287884 ]] || { echo 'Unexpected AWS account' >&2; exit 1; }

case "${1:-}" in
  open)
    : "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
    ip=$(curl --fail --silent --show-error --max-time 15 https://checkip.amazonaws.com)
    cidr=$("$python_bin" - "$ip" <<'PY'
import ipaddress, sys
address = ipaddress.IPv4Address(sys.argv[1])
if not address.is_global:
    raise SystemExit('Runner IP is not public')
print(f'{address}/32')
PY
)
    # Check only rules granting TCP port 22 from this exact address.
    rules=$(aws ec2 describe-security-group-rules --filters \
      "Name=group-id,Values=$EC2_SECURITY_GROUP_ID" --output json)
    existing=$(RULES_JSON="$rules" "$python_bin" - "$cidr" <<'PY'
import json, os, sys
cidr = sys.argv[1]
rules = json.loads(os.environ['RULES_JSON'])['SecurityGroupRules']
print('yes' if any(
    not rule.get('IsEgress', False)
    and rule.get('CidrIpv4') == cidr
    and rule.get('IpProtocol') in ('tcp', '6', '-1')
    and (rule.get('IpProtocol') == '-1' or rule.get('FromPort', 65536) <= 22 <= rule.get('ToPort', -1))
    for rule in rules
) else 'no')
PY
)
    if [[ "$existing" == yes ]]; then
      echo 'SSH access already exists for this runner; leaving the existing rule untouched.'
      exit 0
    fi
    rule_id=''
    rollback() {
      if [[ -n "$rule_id" ]]; then
        aws ec2 revoke-security-group-ingress --group-id "$EC2_SECURITY_GROUP_ID" --security-group-rule-ids "$rule_id" >/dev/null || echo "Failed to roll back $rule_id" >&2
      fi
    }
    trap rollback EXIT
    rule_id=$(aws ec2 authorize-security-group-ingress --group-id "$EC2_SECURITY_GROUP_ID" \
      --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$cidr,Description=Temporary-GitHub-Actions-SSH}]" \
      --query 'SecurityGroupRules[0].SecurityGroupRuleId' --output text)
    [[ "$rule_id" =~ ^sgr-[0-9a-f]+$ ]] || { echo 'AWS did not return a valid rule ID' >&2; exit 1; }
    printf 'rule_id=%s\n' "$rule_id" >> "$GITHUB_OUTPUT"
    trap - EXIT
    ;;
  close)
    rule_id=${2:-}
    [[ "$rule_id" =~ ^sgr-[0-9a-f]+$ ]] || { echo 'Invalid rule ID' >&2; exit 1; }
    aws ec2 revoke-security-group-ingress --group-id "$EC2_SECURITY_GROUP_ID" --security-group-rule-ids "$rule_id" >/dev/null
    ;;
  *) echo 'Usage: runner-ssh-access.sh open | close RULE_ID' >&2; exit 2 ;;
esac

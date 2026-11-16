#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
base=$(mktemp -d)
trap 'rm -f "$base/aws" "$base/curl" "$base/output" "$base/log"; rmdir "$base"' EXIT
export PATH="$base:$PATH" GITHUB_OUTPUT="$base/output" EC2_SECURITY_GROUP_ID=sg-12345678 MOCK_LOG="$base/log"
cat > "$base/aws" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$AWS_REGION" == us-east-1 && "$AWS_DEFAULT_REGION" == us-east-1 ]]
[[ "$1 $2 $3 $4 $5 $6 $7" == '--region us-east-1 --no-cli-pager --cli-connect-timeout 10 --cli-read-timeout 30' ]]
shift 7
printf '%s\n' "$*" >> "$MOCK_LOG"
case "$1 $2" in
  'sts get-caller-identity') echo "${MOCK_ACCOUNT:-109347287884}" ;;
  'ec2 describe-security-group-rules')
    [[ "$*" == *'--filters Name=group-id,Values=sg-12345678 --output json'* ]] || exit 1
    case "${MOCK_EXISTING:-none}" in
      ingress) echo '{"SecurityGroupRules":[{"IsEgress":false,"CidrIpv4":"8.8.8.8/32","IpProtocol":"tcp","FromPort":22,"ToPort":22}]}' ;;
      egress) echo '{"SecurityGroupRules":[{"IsEgress":true,"CidrIpv4":"8.8.8.8/32","IpProtocol":"tcp","FromPort":22,"ToPort":22}]}' ;;
      *) echo '{"SecurityGroupRules":[]}' ;;
    esac ;;
  'ec2 authorize-security-group-ingress') [[ "${MOCK_FAIL:-0}" == 0 ]] || exit 1; echo sgr-abcdef12345678901 ;;
  'ec2 revoke-security-group-ingress') echo '{}' ;;
  *) exit 1 ;;
esac
MOCK
cat > "$base/curl" <<'MOCK'
#!/usr/bin/env bash
echo "${MOCK_IP:-8.8.8.8}"
MOCK
chmod +x "$base/aws" "$base/curl"
export AWS_REGION=eu-west-1 AWS_DEFAULT_REGION=eu-west-1
bash scripts/runner-ssh-access.sh open
grep -q '^rule_id=sgr-abcdef12345678901$' "$GITHUB_OUTPUT"
grep -q 'CidrIp=8.8.8.8/32' "$MOCK_LOG"
bash scripts/runner-ssh-access.sh close sgr-abcdef12345678901
grep -q 'revoke-security-group-ingress.*sgr-abcdef12345678901' "$MOCK_LOG"
: > "$MOCK_LOG"; : > "$GITHUB_OUTPUT"
MOCK_EXISTING=ingress bash scripts/runner-ssh-access.sh open
! grep -q 'authorize-security-group-ingress\|revoke-security-group-ingress' "$MOCK_LOG"
: > "$MOCK_LOG"
MOCK_EXISTING=egress bash scripts/runner-ssh-access.sh open
grep -q 'authorize-security-group-ingress' "$MOCK_LOG"
: > "$MOCK_LOG"
if MOCK_FAIL=1 bash scripts/runner-ssh-access.sh open; then exit 1; fi
! grep -q 'revoke-security-group-ingress' "$MOCK_LOG"
: > "$MOCK_LOG"
if MOCK_ACCOUNT=123456789012 bash scripts/runner-ssh-access.sh open; then exit 1; fi
! grep -q 'ec2 ' "$MOCK_LOG"
: > "$MOCK_LOG"
if MOCK_IP=127.0.0.1 bash scripts/runner-ssh-access.sh open; then exit 1; fi
! grep -q 'authorize-security-group-ingress' "$MOCK_LOG"
: > "$MOCK_LOG"
if GITHUB_OUTPUT="$base/missing/output" bash scripts/runner-ssh-access.sh open; then exit 1; fi
grep -q 'revoke-security-group-ingress.*sgr-abcdef12345678901' "$MOCK_LOG"
echo 'Runner SSH access mock checks passed'

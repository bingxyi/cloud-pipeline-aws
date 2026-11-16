#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python -m pytest -q
PYTHON_BIN=python bash tests/test_runner_ssh_access.sh
for script in validate-local.sh scripts/*.sh; do
  bash -n "$script"
done
docker compose config -q
project="cloud-tasks-smoke-$$"
compose=(docker compose -p "$project")
cleanup() { "${compose[@]}" down --remove-orphans; }
trap cleanup EXIT
"${compose[@]}" build
"${compose[@]}" up -d --no-build
ready=0
for ((i=0; i<30; i++)); do
  if "${compose[@]}" exec -T api python -c 'import urllib.request; urllib.request.urlopen("http://127.0.0.1:8000/health", timeout=2)' >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [[ "$ready" != 1 ]]; then
  "${compose[@]}" logs api
  exit 1
fi
"${compose[@]}" exec -T api python - <<'PY'
import json
from urllib.error import HTTPError
from urllib.request import Request, urlopen
base = 'http://127.0.0.1:8000'
def call(path, method='GET', body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = Request(base + path, data=data, method=method, headers={'Content-Type': 'application/json'})
    try:
        response = urlopen(req, timeout=5)
    except HTTPError as error:
        response = error
    with response:
        return response.status, response.read()
status, body = call('/health')
assert status == 200 and json.loads(body)['status'] == 'ok'
status, body = call('/version')
assert status == 200 and json.loads(body) == {'service': 'cloud-tasks-api', 'version': '1.1.0'}
status, body = call('/tasks', 'POST', {'title': 'local persistence check'})
assert status == 201
status, body = call('/tasks', 'POST', {'title': 'local deletion check'})
assert status == 201
task_id = json.loads(body)['id']
assert call(f'/tasks/{task_id}', 'DELETE') == (204, b'')
status, body = call(f'/tasks/{task_id}', 'DELETE')
assert status == 404 and isinstance(json.loads(body), dict)
PY
"${compose[@]}" up -d --no-deps --force-recreate api
"${compose[@]}" exec -T api python - <<'PY'
import json
import time
from urllib.request import Request, urlopen
base = 'http://127.0.0.1:8000'
for attempt in range(30):
    try:
        with urlopen(base + '/tasks', timeout=2) as response:
            tasks = json.load(response)
        break
    except OSError:
        if attempt == 29:
            raise
        time.sleep(1)
matches = [task for task in tasks if task['title'] == 'local persistence check']
assert len(matches) == 1
with urlopen(Request(base + '/tasks/' + str(matches[0]['id']), method='DELETE'), timeout=5) as response:
    assert response.status == 204 and response.read() == b''
PY
echo "Local validation passed; retained volume: ${project}_cloud-tasks-data"

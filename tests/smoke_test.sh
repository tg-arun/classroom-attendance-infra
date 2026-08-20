#!/usr/bin/env bash
# Smoke test: is the service actually serving after a deploy?
#
#   ./tests/smoke_test.sh                 # reads the URL from terraform output
#   ./tests/smoke_test.sh http://my-alb   # or pass one in
#
# Exits non-zero on the first failure so CI can gate a deploy on it.

set -euo pipefail

URL="${1:-http://$(terraform output -raw alb_dns_name)}"

echo "Testing ${URL}"

status=$(curl -s -o /tmp/smoke_body -w '%{http_code}' --max-time 5 "${URL}")
if [[ "${status}" != "200" ]]; then
  echo "FAIL: expected HTTP 200, got ${status}"
  exit 1
fi
echo "PASS: HTTP 200"

if ! grep -qi "welcome to nginx" /tmp/smoke_body; then
  echo "FAIL: response body is not the nginx welcome page"
  exit 1
fi
echo "PASS: nginx welcome page served"

# The latency SLO is 300ms, so a single slow request is worth knowing about.
latency=$(curl -s -o /dev/null -w '%{time_total}' --max-time 5 "${URL}")
echo "INFO: response time ${latency}s (SLO budget 0.300s)"

echo "Smoke test passed"

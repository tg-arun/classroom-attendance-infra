// Load test for the 6,000 req/s requirement.
//
//   k6 run -e URL=http://<alb-dns-name> tests/load_test.js
//
// The thresholds are the SLOs from the brief, so a passing run is evidence that
// the architecture meets them - not just an opinion that it should.

import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    steady_6k: {
      executor: 'constant-arrival-rate',
      rate: 6000,
      timeUnit: '1s',
      duration: '3m',
      preAllocatedVUs: 500,
      maxVUs: 2000,
    },
  },
  thresholds: {
    // 99.9% success rate
    http_req_failed: ['rate<0.001'],
    // 99.9% of responses within 300ms
    http_req_duration: ['p(99.9)<300'],
  },
};

export default function () {
  const res = http.get(__ENV.URL);
  check(res, { 'status is 200': (r) => r.status === 200 });
}

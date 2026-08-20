#!/bin/bash
set -euo pipefail

# Install nginx and leave the distribution's default welcome page in place -
# that page is what stands in for the Classroom Attendance Service.
dnf install -y nginx

systemctl enable --now nginx

# Copy to terraform.tfvars and adjust. There are no secrets here - credentials
# come from the environment (AWS SSO / OIDC), never from a file in the repo.

project     = "classroom-attendance"
environment = "dev"
region      = "ap-south-1"

az_count        = 2
container_image = "nginx:1.27-alpine"
task_cpu        = 1024
task_memory     = 2048
min_tasks       = 2
max_tasks       = 12

# Send SLO alerts somewhere real before going to production.
alert_email = ""

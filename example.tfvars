# Copy to terraform.tfvars and adjust. There are no secrets here - credentials
# come from the environment (AWS SSO / OIDC), never from a file in the repo.

project     = "classroom-attendance"
environment = "dev"
region      = "us-east-1"

az_count      = 2
instance_type = "c6i.large"
min_size      = 2
max_size      = 12

# Send SLO alerts somewhere real before going to production.
alert_email = ""

# Development environment
#
# Environment specific values live here as literal arguments. There is no
# tfvars indirection: reading this file tells you exactly what dev is.

locals {
  project     = "classroom-attendance-dev"
  environment = "dev"
}

module "network" {
  source = "../../modules/network"

  project  = local.project
  vpc_cidr = "10.0.0.0/16"
  az_count = 2
}

module "service" {
  source = "../../modules/service"

  project            = local.project
  region             = var.region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  min_tasks       = 2
  max_tasks       = 12
  certificate_arn = var.certificate_arn

  # Tasks cannot pull their image until the NAT route exists.
  depends_on = [module.network]
}

module "observability" {
  source = "../../modules/observability"

  project                 = local.project
  region                  = var.region
  alb_arn_suffix          = module.service.alb_arn_suffix
  target_group_arn_suffix = module.service.target_group_arn_suffix
  cluster_name            = module.service.cluster_name
  service_name            = module.service.service_name
  alert_email             = var.alert_email
}

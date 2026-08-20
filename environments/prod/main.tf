# Production environment
#
# Same three modules as dev, different numbers. The differences are the whole
# point of the module layout: they are visible in one file instead of being
# spread through the resources.

locals {
  project     = "classroom-attendance"
  environment = "prod"
}

module "network" {
  source = "../../modules/network"

  project  = local.project
  vpc_cidr = "10.1.0.0/16"

  # Three AZs, so losing one costs a third of capacity rather than a half.
  az_count = 3
}

module "service" {
  source = "../../modules/service"

  project            = local.project
  region             = var.region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  # Enough headroom to absorb 6,000 req/s without waiting for a scale-out, and
  # room to double from there.
  min_tasks = 6
  max_tasks = 24

  certificate_arn            = var.certificate_arn
  enable_deletion_protection = true
  log_retention_days         = 90
  access_logs_retention_days = 90

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

# Unit tests for the service module. Plan only, with placeholder network ids -
# no VPC is needed and nothing is created.
#
#   terraform -chdir=modules/service test

variables {
  project            = "test-service"
  region             = "ap-south-1"
  vpc_id             = "vpc-00000000000000001"
  public_subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
  private_subnet_ids = ["subnet-00000000000000003", "subnet-00000000000000004"]
}

run "tasks_are_not_reachable_from_the_internet" {
  command = plan

  assert {
    condition     = aws_lb.main.internal == false
    error_message = "The load balancer must be internet facing."
  }

  assert {
    condition     = aws_ecs_service.web.network_configuration[0].assign_public_ip == false
    error_message = "Tasks must not be given public IP addresses."
  }

  assert {
    condition     = aws_lb_target_group.web.target_type == "ip"
    error_message = "Fargate tasks are registered by IP, not by instance."
  }
}

run "deploys_cannot_spend_the_error_budget" {
  command = plan

  assert {
    condition     = aws_ecs_service.web.deployment_minimum_healthy_percent == 100
    error_message = "A deploy must never drop below the capacity already in service."
  }

  assert {
    condition     = aws_ecs_service.web.deployment_circuit_breaker[0].rollback
    error_message = "A failed deploy must roll itself back."
  }

  assert {
    condition     = aws_lb_target_group.web.health_check[0].path == "/"
    error_message = "Health checks should hit the nginx welcome page."
  }
}

run "scales_beyond_the_required_throughput" {
  command = plan

  variables {
    max_tasks = 12
  }

  # 12 tasks x 1,000 req/s per task = 12,000 req/s, double the 6,000 req/s
  # requirement.
  assert {
    condition     = aws_appautoscaling_target.web.max_capacity * 1000 >= 6000
    error_message = "Maximum capacity must leave headroom above 6,000 req/s."
  }
}

run "certificate_turns_on_https_and_redirects_http" {
  command = plan

  variables {
    certificate_arn = "arn:aws:acm:ap-south-1:111122223333:certificate/test"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "A certificate must produce an HTTPS listener."
  }

  assert {
    condition     = aws_lb_listener.http_redirect[0].default_action[0].type == "redirect"
    error_message = "Port 80 must redirect to HTTPS once a certificate exists."
  }

  assert {
    condition     = length(aws_lb_listener.http_forward) == 0
    error_message = "Plain HTTP must not be served when a certificate is configured."
  }
}

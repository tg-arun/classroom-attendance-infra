# Terraform's built-in tests. These run a plan only - nothing is created and
# nothing costs money, so they are safe to run on every pull request.
#
#   terraform test

run "defaults_are_highly_available" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) >= 2
    error_message = "The web tier must live in at least two Availability Zones."
  }

  assert {
    condition     = aws_appautoscaling_target.web.min_capacity >= 2
    error_message = "Losing one task must not take the service down."
  }

  assert {
    condition     = aws_ecs_service.web.deployment_minimum_healthy_percent == 100
    error_message = "A deploy must never drop below the capacity already in service."
  }

  assert {
    condition     = aws_ecs_service.web.deployment_circuit_breaker[0].rollback
    error_message = "A failed deploy must roll itself back."
  }
}

run "load_balancer_is_the_only_public_entrypoint" {
  command = plan

  assert {
    condition     = aws_lb.main.internal == false
    error_message = "The load balancer must be internet facing."
  }

  assert {
    condition     = aws_lb_target_group.web.health_check[0].path == "/"
    error_message = "Health checks should hit the nginx welcome page."
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

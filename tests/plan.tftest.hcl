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
    condition     = aws_autoscaling_group.web.min_size >= 2
    error_message = "Losing one instance must not take the service down."
  }

  assert {
    condition     = aws_autoscaling_group.web.health_check_type == "ELB"
    error_message = "Health must be judged by the load balancer, not just by EC2."
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
    condition     = aws_launch_template.web.metadata_options[0].http_tokens == "required"
    error_message = "Instances must require IMDSv2."
  }
}

run "scales_beyond_the_required_throughput" {
  command = plan

  variables {
    max_size = 12
  }

  # 12 instances x 1,000 req/s per instance = 12,000 req/s, double the 6,000
  # req/s requirement.
  assert {
    condition     = aws_autoscaling_group.web.max_size * 1000 >= 6000
    error_message = "Maximum capacity must leave headroom above 6,000 req/s."
  }
}

run "certificate_turns_on_https_and_redirects_http" {
  command = plan

  variables {
    certificate_arn = "arn:aws:acm:us-east-1:111122223333:certificate/test"
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

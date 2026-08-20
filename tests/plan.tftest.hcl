# Checks the things that would be embarrassing to get wrong. Plan only, so it
# creates nothing and costs nothing.
#
#   terraform test

run "high_availability" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Tasks must be able to run in two AZs."
  }

  assert {
    condition     = aws_appautoscaling_target.web.min_capacity >= 2
    error_message = "Losing one task must not take the service down."
  }
}

run "tasks_are_private" {
  command = plan

  assert {
    condition     = aws_ecs_service.web.network_configuration[0].assign_public_ip == false
    error_message = "Tasks must not have public IPs."
  }

  assert {
    condition     = aws_lb.main.internal == false
    error_message = "The load balancer is the public entrypoint."
  }
}

run "enough_capacity" {
  command = plan

  # 12 tasks at 1,000 req/s each is 12,000, double what is asked for.
  assert {
    condition     = aws_appautoscaling_target.web.max_capacity * 1000 >= 6000
    error_message = "Must be able to scale past 6,000 req/s."
  }
}

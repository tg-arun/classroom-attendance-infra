# Scaling
#
# Capacity tracks requests per task rather than CPU: it reacts to the thing our
# SLO is about (traffic) instead of a proxy for it. The maths behind the default
# target is in the README.
#
# Terraform sets the starting task count and then stops managing it. If it kept
# managing it, an unrelated apply during a busy period would reset the service
# back to min_tasks and drop traffic on the floor.

resource "aws_appautoscaling_target" "web" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}

resource "aws_appautoscaling_policy" "request_count" {
  name               = "${var.project}-target-tracking"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.web.service_namespace
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }

    target_value = var.requests_per_target

    # Scale out quickly, scale in slowly. Being briefly over-provisioned is
    # cheap; being under-provisioned costs error budget.
    scale_out_cooldown = 30
    scale_in_cooldown  = 180
  }
}

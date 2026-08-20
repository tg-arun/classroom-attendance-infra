# Auto Scaling group
#
# Capacity is driven by requests per instance rather than CPU: it reacts to the
# thing our SLO is about (traffic) instead of a proxy for it. The maths behind
# the default target is in the README.

resource "aws_autoscaling_group" "web" {
  name                = "${var.project}-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]

  min_size = var.min_size
  max_size = var.max_size

  # desired_capacity is deliberately not set. Scaling owns it at runtime; if
  # Terraform managed it too, an unrelated apply during a busy period would
  # scale the fleet back down to min_size. See the ignore_changes below.

  # Use the load balancer's view of health, not just "is the VM running".
  health_check_type = "ELB"

  # Long enough for the instance to boot and install nginx before its first
  # health check counts against it.
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # A launch template change rolls out one batch at a time and keeps at least
  # 90% of the fleet in service, so a deploy never breaks the SLO.
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-web"
    propagate_at_launch = true
  }

  # Group level metrics, so the dashboard can show desired vs in-service
  # capacity rather than only what the load balancer sees.
  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
  ]

  # Instances need the NAT route to exist before they can install nginx,
  # otherwise the first ones launched fail their health check and get replaced.
  depends_on = [aws_route_table_association.private]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "request_count" {
  name                      = "${var.project}-target-tracking"
  autoscaling_group_name    = aws_autoscaling_group.web.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }

    target_value = var.requests_per_target
  }
}

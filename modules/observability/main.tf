# Observability
#
# Two alarms map directly onto the two SLOs, one alarm covers capacity loss:
#
#   99.9% success rate      -> 5xx responses stay under 0.1% of requests
#   99.9% under 300ms       -> p99.9 of TargetResponseTime stays under 0.3s
#   capacity                -> no unhealthy targets behind the load balancer
#
# Everything alarms into one SNS topic so paging routing lives in one place.

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.project}-slo-error-rate"
  alarm_description   = "5xx rate above 0.1% - burning the 99.9% success SLO."
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.error_rate_threshold
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "error_rate"
    expression  = "100 * (target_5xx + elb_5xx) / requests"
    label       = "5xx rate (%)"
    return_data = true
  }

  metric_query {
    id = "requests"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      stat        = "Sum"
      period      = 60
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
    }
  }

  metric_query {
    id = "target_5xx"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      stat        = "Sum"
      period      = 60
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
    }
  }

  metric_query {
    id = "elb_5xx"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      stat        = "Sum"
      period      = 60
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${var.project}-slo-latency"
  alarm_description   = "p99.9 response time above 300ms - burning the latency SLO."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p99.9"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.latency_threshold_seconds
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project}-unhealthy-hosts"
  alarm_description   = "At least one target is failing its health check."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

# One dashboard with the three numbers we would look at during an incident.
resource "aws_cloudwatch_dashboard" "slo" {
  dashboard_name = "${var.project}-slo"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Requests per second"
          region = var.region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Response time (p99.9) vs 300ms budget"
          region = var.region
          view   = "timeSeries"
          stat   = "p99.9"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
          annotations = {
            horizontal = [{ label = "SLO", value = var.latency_threshold_seconds }]
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "5xx responses"
          region = var.region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Task CPU and memory"
          region = var.region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Healthy targets"
          region = var.region
          view   = "timeSeries"
          stat   = "Minimum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix]
          ]
        }
      }
    ]
  })
}

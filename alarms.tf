# Alarms for the two SLOs: 99.9% of requests succeed, 99.9% under 300ms.

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 5xx as a percentage of requests. Counting errors alone would page at 3am for
# three errors in a quiet hour.
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.project}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.1
  evaluation_periods  = 2
  alarm_description   = "More than 0.1% of requests are failing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "100 * errors / requests"
    label       = "5xx rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"

    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
    }
  }

  metric_query {
    id = "requests"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
    }
  }
}

# p99 rather than average: an average hides the slow tail the SLO is about.
resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${var.project}-latency"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.3
  evaluation_periods  = 2
  period              = 60
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  extended_statistic  = "p99"
  alarm_description   = "p99 response time is over the 300ms SLO"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = aws_lb.main.arn_suffix }
}

# Capacity, not correctness: fewer than two healthy tasks means one AZ failure
# away from an outage.
resource "aws_cloudwatch_metric_alarm" "healthy_tasks" {
  alarm_name          = "${var.project}-healthy-tasks"
  comparison_operator = "LessThanThreshold"
  threshold           = 2
  evaluation_periods  = 2
  period              = 60
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Minimum"
  alarm_description   = "Fewer than two healthy tasks behind the load balancer"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }
}

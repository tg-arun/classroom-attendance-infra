# The service
#
# Tasks need the NAT route to exist before they can pull the image. That
# dependency now lives at the call site as depends_on = [module.network],
# because the route table is no longer in this module.
#
# nginx runs as a Fargate task: no EC2 instances, no AMI to patch, no packages
# installed at boot. The image is pinned to a version rather than :latest, so a
# scale-out event cannot quietly change what is running.

resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${var.project}"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_cluster" "main" {
  name = var.project

  # Container Insights gives per-task CPU and memory without running an agent.
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      # Health is judged by the load balancer, which is the thing that decides
      # whether a task receives traffic. A second container-level check would
      # only add a way for the two to disagree.
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "web" {
  name            = "${var.project}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  launch_type     = "FARGATE"
  desired_count   = var.min_tasks

  # Audited debug shell into a running task, in place of SSH.
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "nginx"
    container_port   = 80
  }

  health_check_grace_period_seconds = 30

  # Never drop below the current capacity during a deploy: start the new tasks
  # first, then drain the old ones.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # A deploy that cannot pass health checks rolls itself back instead of
  # sitting there half broken.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Scaling owns the task count at runtime - see the note in scaling.tf.
  lifecycle {
    ignore_changes = [desired_count]
  }
}

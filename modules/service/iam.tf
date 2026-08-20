# Task roles
#
# Two roles, because they are used by different things at different times:
#
#   execution role - used by ECS itself to pull the image and write logs
#   task role      - used by the container while it runs
#
# nginx needs no AWS permissions of its own, so the task role only carries what
# ECS Exec needs for a debug shell. There is no host to log into and no SSH key
# anywhere in this stack.

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.project}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.project}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

# ECS Exec replaces SSH: an audited shell into a running container, with no
# inbound port and no key material.
data "aws_iam_policy_document" "ecs_exec" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_exec" {
  name   = "${var.project}-ecs-exec"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.ecs_exec.json
}

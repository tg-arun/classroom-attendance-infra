# The load balancer is the only thing with a public address. Tasks only accept
# traffic from its security group.

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb"
  description = "Public entrypoint"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "alb_in" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from anywhere"
}

resource "aws_security_group_rule" "alb_out" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tasks.id
  description              = "To the tasks"
}

resource "aws_security_group" "tasks" {
  name        = "${var.project}-tasks"
  description = "nginx tasks"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "tasks_in" {
  security_group_id        = aws_security_group.tasks.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Only from the load balancer"
}

# Needed to pull the image and write logs.
resource "aws_security_group_rule" "tasks_out" {
  security_group_id = aws_security_group.tasks.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound"
}

resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "web" {
  name        = "${var.project}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Fargate tasks get their own ENI

  health_check {
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # Long enough to finish in-flight requests, short enough that a scale-in is
  # not slow.
  deregistration_delay = 30
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

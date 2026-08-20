# Security groups
#
# The only thing exposed to the internet is the load balancer on port 80.
# Tasks accept traffic from the load balancer's security group and nothing
# else - there is no SSH port and no key pair anywhere in this stack.

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Allows inbound HTTP to the load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = length(var.allowed_http_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from allowed clients"
  cidr_ipv4         = var.allowed_http_cidrs[count.index]
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Only exists when a certificate is configured - see alb.tf.
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = var.certificate_arn == "" ? 0 : length(var.allowed_http_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from allowed clients"
  cidr_ipv4         = var.allowed_http_cidrs[count.index]
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward requests to the web tier"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "web" {
  name        = "${var.project}-web-sg"
  description = "nginx tasks - only reachable from the load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from the load balancer only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# Outbound is needed to pull the container image and to reach the ECS and
# CloudWatch endpoints.
resource "aws_vpc_security_group_egress_rule" "web_egress" {
  security_group_id = aws_security_group.web.id
  description       = "Outbound for image pulls, logs and ECS Exec"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

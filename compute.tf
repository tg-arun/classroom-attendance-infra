# Web tier launch template
#
# Amazon Linux 2023 + nginx, built from the latest AMI published by AWS. The
# AMI id is read from SSM at plan time so we never pin a stale image by hand.

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project}-web-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(file("${path.module}/templates/user_data.sh"))

  # IMDSv2 only - blocks the SSRF-to-credentials path that IMDSv1 allows.
  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
      volume_type = "gp3"
      encrypted   = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project}-web"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

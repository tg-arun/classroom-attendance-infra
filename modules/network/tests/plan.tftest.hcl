# Unit tests for the network module. Plan only - nothing is created.
#
#   terraform -chdir=modules/network test

variables {
  project  = "test-network"
  vpc_cidr = "10.9.0.0/16"
  az_count = 2
}

run "spreads_across_availability_zones" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) >= 2
    error_message = "The service must be able to live in at least two Availability Zones."
  }

  assert {
    condition     = length(aws_subnet.public) == length(aws_subnet.private)
    error_message = "Every AZ needs both a public and a private subnet."
  }
}

run "private_subnets_stay_private" {
  command = plan

  assert {
    condition     = aws_subnet.private[0].map_public_ip_on_launch == false
    error_message = "Private subnets must not hand out public IP addresses."
  }
}

run "a_third_az_is_one_variable" {
  command = plan

  variables {
    az_count = 3
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "az_count must drive how many subnets are created."
  }
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnets, one per AZ - for the load balancer."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnets, one per AZ - for the tasks."
  value       = aws_subnet.private[*].id
}

output "subnet_ids" {
  value = aws_subnet.subnets[*].id
}

output "vpc_id" {
  value = aws_vpc.custom_vpc.id
}
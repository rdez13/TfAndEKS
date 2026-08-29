output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs — worker nodes are placed here."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs — the ALB and NAT gateway live here."
  value       = module.vpc.public_subnets
}

output "availability_zones" {
  description = "Availability zones the subnets span."
  value       = local.azs
}

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

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = module.eks.cluster_endpoint
}

# Every IRSA role in later phases trusts this OIDC provider.
output "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider, used for IRSA."
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Command to point kubectl at this cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region} --profile ${var.aws_profile}"
}

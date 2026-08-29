# Config lives here with defaults rather than in a .tfvars file, because *.tfvars is
# gitignored — anything put there would not survive a fresh clone.

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile. Pinned so credentials never fall back to the default profile, which points at a different account."
  type        = string
  default     = "tfeks"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. Terraform refuses to run if the resolved credentials belong to any other account."
  type        = string
  default     = "793593623012"
}

variable "project_name" {
  description = "Short project identifier used to name and tag resources."
  type        = string
  default     = "tfandeks"
}

variable "github_repo" {
  description = "GitHub repository in owner/name form. Used by the Argo CD Applications and the CI OIDC trust policy."
  type        = string
  default     = "rdez13/TfAndEKS"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "tfandeks-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC. Must not overlap the account's default VPC (172.31.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across. EKS requires at least 2."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "EKS requires subnets in at least 2 availability zones."
  }
}

variable "app_name" {
  description = "Name of the demo application. Used for the ECR repository, Kubernetes namespace, and workload names."
  type        = string
  default     = "demo-app"
}

variable "ecr_image_retention_count" {
  description = "Number of tagged images to keep in ECR before the lifecycle policy expires older ones."
  type        = number
  default     = 10
}

variable "kubernetes_version" {
  description = "EKS control plane version. Must be in AWS standard support."
  type        = string
  default     = "1.34"
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

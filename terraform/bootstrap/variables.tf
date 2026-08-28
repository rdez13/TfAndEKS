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

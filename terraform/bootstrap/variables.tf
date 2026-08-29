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

# Deliberately has NO default: this repo is public, and a default would commit a personal
# email address to it. Supplied via terraform.tfvars, which is gitignored.
variable "alert_email" {
  description = "Email address that receives budget alerts."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "budget_limit_usd" {
  description = "Monthly spend ceiling in USD. Alerts at 50% actual and 100% forecast."
  type        = string
  default     = "20"
}

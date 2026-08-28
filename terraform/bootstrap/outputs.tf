output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state for the main stack."
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.tfstate.arn
}

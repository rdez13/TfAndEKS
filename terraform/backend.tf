# State lives in the S3 bucket created by terraform/bootstrap.
#
# Backend blocks cannot reference variables, so the bucket name is literal here. It is
# "${project_name}-tfstate-${aws_account_id}" from the bootstrap module.
#
# use_lockfile enables S3-native state locking (Terraform 1.10+), which replaces the
# DynamoDB lock table older guides still tell you to create.

terraform {
  backend "s3" {
    bucket       = "tfandeks-tfstate-793593623012"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    profile      = "tfeks"
    encrypt      = true
    use_lockfile = true
  }
}

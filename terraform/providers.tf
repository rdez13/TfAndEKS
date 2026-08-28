provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Hard stop if credentials resolve to any account other than the expected one.
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

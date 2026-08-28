# Bootstrap: creates the S3 bucket that stores Terraform state for the main stack.
#
# This root module is applied ONCE with local state, because the backend it creates
# cannot store its own state before it exists. Its terraform.tfstate is gitignored and
# lives only on the operator's machine. If that file is lost, re-import rather than
# re-apply:  terraform import aws_s3_bucket.tfstate <bucket-name>

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Hard stop if credentials resolve to any account other than the expected one.
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Component = "bootstrap"
    }
  }
}

locals {
  # Account ID suffix gives the globally-unique name S3 requires.
  state_bucket_name = "${var.project_name}-tfstate-${var.aws_account_id}"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket_name

  # Refuse to delete while state objects still exist. Terraform state is the one thing
  # in this project that is genuinely painful to lose.
  force_destroy = false
}

# Versioning is what makes state recoverable after a bad apply or a corrupted write.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State files contain resource attributes in plaintext, so the bucket is never public
# regardless of how relaxed the rest of this project is about security.
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

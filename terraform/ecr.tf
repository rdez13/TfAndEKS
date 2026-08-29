# Private container registry for the demo app. GitHub Actions pushes images here tagged
# with the commit SHA; the node group's IAM role already carries
# AmazonEC2ContainerRegistryReadOnly, so nodes can pull without extra credentials.

resource "aws_ecr_repository" "app" {
  name = var.app_name

  # Tags are mutable so CI can move a floating tag if needed. Images are still pushed
  # with an immutable commit-SHA tag, which is what the deployment actually references.
  image_tag_mutability = "MUTABLE"

  # Without this, `terraform destroy` fails once any image has been pushed:
  # "RepositoryNotEmptyException". This project is destroyed and rebuilt repeatedly.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true # basic scanning is free
  }

  tags = {
    Component = "ecr"
  }
}

# Untagged images accumulate every time a tag is overwritten. Expiring them keeps the
# repo from growing without bound; the tagged rule caps history.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the most recent ${var.ecr_image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_image_retention_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

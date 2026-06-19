################ ECR Repository ################
resource "aws_ecr_repository" "this" {
  name = "${var.project_name}-${var.env_name}-ecr"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE" 

  force_delete = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-ecr"
  })
}

################ ECR Lifecycle Policy ################
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      for idx, service in values(var.pipelines) : {
        rulePriority = idx + 1
        description  = service.service_name
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["${service.service_name}_"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

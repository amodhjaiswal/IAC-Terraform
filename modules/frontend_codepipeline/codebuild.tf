#######################################
# AWS CodeBuild Project
#######################################

resource "aws_codebuild_project" "this" {
  name         = "${local.name_prefix}-${var.frontend_bucket_name}-frontend-codebuild"
  description  = "CodeBuild project for ${var.frontend_bucket_name}-frontend"
  service_role = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
    name = "build_output"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE" # 8 vCPUs, 16 GiB
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "BUCKET_NAME"
      value = var.bucket_name
    }
    environment_variable {
      name  = "DISTRO_NAME"
      value = var.cloudfront_distribution_id
    }
    environment_variable {
      name  = "ENV_NAME"
      value = var.env_name
    }
    
  }

  # Inline build commands (instead of buildspec.yml)
  source {
    type = "CODEPIPELINE"

    buildspec = <<EOF
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 20

  pre_build:
    commands:
      - echo "Installing source NPM dependencies..."
      - npm install
      - npm install -g @angular/cli@19.0.5

  build:
    commands:
      - echo "Build started on `date`"
      - ng build --configuration=$ENV_NAME

  post_build:
    commands:
      - echo "Sending build to S3..."
      - aws s3 sync dist/ s3://$BUCKET_NAME/ --delete
      - echo "Build completed on `date`"
      - aws cloudfront create-invalidation --distribution-id=$DISTRO_NAME --paths '/*'
      - echo "Cloudfront invalidation completed at `date`"

artifacts:
  files:
    - '**/*'
  base-directory: 'dist*'
  discard-paths: yes
EOF
  }

  tags = local.tags
}

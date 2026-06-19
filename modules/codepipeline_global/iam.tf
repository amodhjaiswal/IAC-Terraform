############################################
# CodePipeline IAM Role
############################################

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.name_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
        ]
      },
      {
        Sid    = "CodePipelineServices"
        Effect = "Allow"
        Action = [
          "codebuild:*",
          "codestar-connections:*",
          "codecommit:*",
          "cloudwatch:*",
          "logs:*",
          "sns:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowPassRoleToCodeBuild"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.codebuild_role.arn
      }
    ]
  })
}

############################################
# CodeBuild IAM Role
############################################

resource "aws_iam_role" "codebuild_role" {
  name = "${local.name_prefix}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${local.name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketsAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*",
          "arn:aws:s3:::${var.admin_bucket_name}",
          "arn:aws:s3:::${var.admin_bucket_name}/*"
        ]
      },
      {
        Sid    = "LogsAndCloudFront"
        Effect = "Allow"
        Action = [
          "logs:*",
          "cloudfront:*",
          "ecr:*"
        ]
        Resource = "*"
      }
    ]
  })
}

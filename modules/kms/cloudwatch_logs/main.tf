#######################################
# Data Sources
#######################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#######################################
# Locals
#######################################
locals {
  name_prefix = "${var.project_name}-${var.env_name}"
  common_tags = merge({
    Name        = "${local.name_prefix}-cloudwatch-logs-kms"
    Project     = var.project_name
    Environment = var.env_name
  }, var.tags)
}

#######################################
# KMS Key for CloudWatch Logs
#######################################
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

#######################################
# KMS Key Alias
#######################################
resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${local.name_prefix}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

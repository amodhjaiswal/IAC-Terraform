terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_sns_topic" "topic" {
  name         = "${var.project_name}-${var.env_name}-${var.resource_name}"
  display_name = "${var.project_name}-${var.env_name}-${var.resource_name}"
}

resource "aws_sns_topic_policy" "topic_policy" {
  arn = aws_sns_topic.topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodeStarNotifications"
        Effect = "Allow"
        Principal = {
          Service = "codestar-notifications.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.topic.arn
      },
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.topic.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.emails)
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.emails[count.index]
}

# Local variables for naming convention
locals {
  name_prefix = "${var.project_name}-${var.env_name}"
  tags = merge(var.tags, {
    Module = "frontend-waf"
  })
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "main" {
  name  = "${local.name_prefix}-frontend-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: IP Reputation Rule
  rule {
    name     = "${local.name_prefix}-ip-reputation-rule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-ip-reputation-rule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Anonymous IP Rule
  rule {
    name     = "${local.name_prefix}-anonymous-ip-rule"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-anonymous-ip-rule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: AWS Managed Known Bad Inputs Rule Set
  rule {
    name     = "${local.name_prefix}-aws-known-bad-inputs"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-aws-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: AWS Managed Core Rule Set
  rule {
    name     = "${local.name_prefix}-aws-core-rule-set"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-aws-core-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: AWS Managed Linux Rule Set
  rule {
    name     = "${local.name_prefix}-aws-linux-rule-set"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-aws-linux-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 6: AWS Managed SQL Injection Rule Set
  rule {
    name     = "${local.name_prefix}-aws-sqli-rule-set"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-aws-sqli-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 7: Rate Limiting Rule
  rule {
    name     = "${local.name_prefix}-rate-limit-rule"
    priority = 7

    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-rate-limit-rule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 8: Geo Blocking Rule
  rule {
    name     = "${local.name_prefix}-geo-block-rule"
    priority = 8

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.blocked_countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-geo-block-rule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 9: Custom IP Allowlist Rule
  rule {
    name     = "${local.name_prefix}-ip-allowlist-rule"
    priority = 9

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowlist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-ip-allowlist-rule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 10: Custom IP Blacklist Rule
  rule {
    name     = "${local.name_prefix}-ip-blacklist-rule"
    priority = 10

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocklist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-ip-blacklist-rule"
      sampled_requests_enabled   = true
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-frontend-waf"
    sampled_requests_enabled   = true
  }
}

# IP Set for Allowlist
resource "aws_wafv2_ip_set" "allowlist" {
  name               = "${local.name_prefix}-ip-allowlist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allowlist_ips

  tags = local.tags
}

# IP Set for Blocklist
resource "aws_wafv2_ip_set" "blocklist" {
  name               = "${local.name_prefix}-ip-blocklist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blocklist_ips

  tags = local.tags
}

# CloudWatch Log Group for WAF logs with KMS encryption
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.region}-${var.env_name}-frontend"
  retention_in_days = var.waf_logs_retention
  kms_key_id        = var.kms_key_id

  tags = local.tags
}

# WAF logging configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

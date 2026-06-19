# Local variables for naming convention
locals {
  name_prefix = "${var.project_name}-${var.env_name}"
  tags = merge(var.tags, {
    Module = "waf"
  })
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "${local.name_prefix}-waf"
  scope = var.scope

  default_action {
    allow {}
  }

  # Rule 0: Custom IP Whitelist Rule (1 WCU)
  rule {
    name     = "${local.name_prefix}-ip-whitelist-rule"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.whitelist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-ip-whitelist-rule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 1: IP Reputation Rule (25 WCU)
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

  # Rule 2: Anonymous IP Rule (50 WCU)
  rule {
    name     = "${local.name_prefix}-anonymous-ip-rule"
    priority = 2

    override_action {
      count {}
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

  # Rule 3: AWS Managed Known Bad Inputs Rule Set (200 WCU)
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

  # Rule 4: Allow Large Body for Dashboard Import
  rule {
    name     = "${local.name_prefix}-large-body-allow"
    priority = 4

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string         = "/api/dashboards/import"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-large-body-allow"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: AWS Managed Core Rule Set with Size Restriction Override (700 WCU)
  rule {
    name     = "${local.name_prefix}-aws-core-rule-set"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "NoUserAgent_HEADER"
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "UserAgent_BadBots_HEADER"
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_QUERYSTRING"
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "CrossSiteScripting_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-aws-core-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 6: AWS Managed Linux Rule Set (200 WCU)
  rule {
    name     = "${local.name_prefix}-aws-linux-rule-set"
    priority = 6

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

  # Rule 7: AWS Managed SQL Injection Rule Set (200 WCU)
  rule {
    name     = "${local.name_prefix}-aws-sqli-rule-set"
    priority = 7

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

  # Rule 8: Rate Limiting Rule (2 WCU)
  rule {
    name     = "${local.name_prefix}-rate-limit-rule"
    priority = 8

    action {
      block {}
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

  # Rule 9: Geo Blocking Rule (1 WCU)
  rule {
    name     = "${local.name_prefix}-geo-block-rule"
    priority = 9

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

  # Rule 10: Custom IP Blacklist Rule (1 WCU)
  rule {
    name     = "${local.name_prefix}-ip-blacklist-rule"
    priority = 10

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blacklist.arn
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
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

# IP Set for Whitelist
resource "aws_wafv2_ip_set" "whitelist" {
  name               = "${local.name_prefix}-ip-whitelist"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips

  tags = local.tags
}

# IP Set for Blacklist
resource "aws_wafv2_ip_set" "blacklist" {
  name               = "${local.name_prefix}-ip-blacklist"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.blacklist_ips

  tags = local.tags
}

# CloudWatch Log Group for WAF logs with KMS encryption
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.env_name}"
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
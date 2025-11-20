#######################################
# Locals
#######################################
locals {
  name_prefix = "${var.project_name}-${var.env_name}"
  common_tags = merge({
    Name        = local.name_prefix
    Project     = var.project_name
    Environment = var.env_name
  }, var.tags)
}

#######################################
# Security Group for EKS Control Plane
#######################################
resource "aws_security_group" "eks_controlplane" {
  name        = "${local.name_prefix}-eks-cp-sg"
  description = "EKS control plane security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow inbound from bastion host"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

#######################################
# CloudWatch Log Group for EKS Logs
# (ENCRYPTED WITH CUSTOMER KMS KEY)
#######################################
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.name_prefix}-eks/cluster"
  retention_in_days = var.eks_logs_retention
  kms_key_id        = var.kms_key_id        # <-- ONLY logs use KMS encryption
  tags              = local.common_tags
}

#######################################
# EKS Cluster
#######################################
resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_controlplane.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.eks_cluster   # ENSURE LOG GROUP CREATED FIRST
  ]
}

#######################################
# EKS Addons
#######################################
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.managed_nodes]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.managed_nodes]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.managed_nodes]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.managed_nodes]
}

#######################################
# Launch Template (UNCHANGED — NO KMS)
#######################################
resource "aws_launch_template" "node_lt" {
  name_prefix   = "${local.name_prefix}-lt-"
  instance_type = var.node_instance_type

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.node_root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true          # <-- unchanged
      # NO KMS KEY HERE (as you requested)
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.name_prefix}-node" })
  }
}

#######################################
# EKS Managed Node Group
#######################################
resource "aws_eks_node_group" "managed_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}-managed-ng"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  capacity_type = var.node_capacity_type

  launch_template {
    id      = aws_launch_template.node_lt.id
    version = "$Latest"
  }

  labels = var.node_labels

  tags = merge(local.common_tags, {
    Name                                = "${local.name_prefix}-node"
    "k8s.io/cluster-autoscaler/enabled" = tostring(var.enable_cluster_autoscaler)
  })

  depends_on = [
    aws_eks_cluster.this,
    aws_launch_template.node_lt,
  ]
}

#######################################
# OIDC Provider
#######################################
resource "aws_iam_openid_connect_provider" "oidc" {
  count           = var.create_oidc_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.this]
}

#######################################
# EKS Access Entries — CodeBuild
#######################################
resource "aws_eks_access_entry" "codebuild_access" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.codebuild_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "codebuild_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.codebuild_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.codebuild_access]
}

resource "aws_eks_access_policy_association" "codebuild_admin_view" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.codebuild_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.codebuild_access]
}

#######################################
# EKS Access Entries — Bastion
#######################################
resource "aws_eks_access_entry" "bastion_access" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.bastion_ssm_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.bastion_ssm_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion_access]
}

resource "aws_eks_access_policy_association" "bastion_admin_view" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.bastion_ssm_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion_access]
}

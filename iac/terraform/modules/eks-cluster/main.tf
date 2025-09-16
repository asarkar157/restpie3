# EKS Cluster Terraform Module
# This module creates an EKS cluster with associated IAM roles and policies

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for AWS partition
data "aws_partition" "current" {}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.additional_security_group_ids
  }

  # Enable EKS Cluster logging
  enabled_cluster_log_types = var.cluster_log_types

  # Encryption configuration
  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# EKS Node Group
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  # Instance configuration
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  ami_type       = each.value.ami_type

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = each.value.max_unavailable_percentage
  }

  # Remote access configuration
  dynamic "remote_access" {
    for_each = each.value.key_name != null ? [1] : []
    content {
      ec2_ssh_key               = each.value.key_name
      source_security_group_ids = each.value.source_security_group_ids
    }
  }

  # Launch template configuration
  dynamic "launch_template" {
    for_each = each.value.launch_template != null ? [each.value.launch_template] : []
    content {
      id      = launch_template.value.id
      version = launch_template.value.version
    }
  }

  # Taints
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Labels
  labels = each.value.labels

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${var.cluster_name}-${each.key}"
    }
  )
}

# EKS Fargate Profile
resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = aws_iam_role.eks_fargate_role[0].arn
  subnet_ids             = var.private_subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${var.cluster_name}-${each.key}"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_fargate_pod_execution_role_policy,
  ]
}

# EKS Add-ons
resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts
  resolve_conflicts_on_update = each.value.resolve_conflicts
  service_account_role_arn    = each.value.service_account_role_arn

  tags = merge(
    var.tags,
    each.value.tags
  )

  depends_on = [
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this,
  ]
}

# CloudWatch Log Group for EKS Cluster
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = length(var.cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = var.tags
}

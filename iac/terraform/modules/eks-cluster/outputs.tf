# Outputs for EKS Cluster Module

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.this.status
}

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = try(aws_iam_openid_connect_provider.eks_cluster_oidc[0].arn, null)
}

output "node_groups" {
  description = "Map of attribute maps for all EKS node groups created"
  value       = aws_eks_node_group.this
}

output "fargate_profiles" {
  description = "Map of attribute maps for all EKS Fargate profiles created"
  value       = aws_eks_fargate_profile.this
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value = flatten([
    for group in aws_eks_node_group.this : group.resources[0].autoscaling_groups[*].name
  ])
}

output "node_group_iam_role_name" {
  description = "IAM role name for EKS node groups"
  value       = aws_iam_role.eks_node_group_role.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN for EKS node groups"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "fargate_profile_iam_role_name" {
  description = "IAM role name for EKS Fargate profiles"
  value       = try(aws_iam_role.eks_fargate_role[0].name, null)
}

output "fargate_profile_iam_role_arn" {
  description = "IAM role ARN for EKS Fargate profiles"
  value       = try(aws_iam_role.eks_fargate_role[0].arn, null)
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = try(aws_iam_role.aws_load_balancer_controller[0].arn, null)
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver"
  value       = try(aws_iam_role.ebs_csi_driver[0].arn, null)
}

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = try(aws_cloudwatch_log_group.eks_cluster[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = try(aws_cloudwatch_log_group.eks_cluster[0].arn, null)
}

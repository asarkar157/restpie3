# Variables for EKS Cluster Module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "subnet_ids" {
  description = "List of subnet IDs where the EKS cluster will be deployed"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups and Fargate profiles"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch logs"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS Key ID to use for encrypting CloudWatch logs"
  type        = string
  default     = null
}

variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types             = list(string)
    capacity_type              = string
    disk_size                  = number
    ami_type                   = string
    desired_size               = number
    max_size                   = number
    min_size                   = number
    max_unavailable_percentage = number
    key_name                   = string
    source_security_group_ids  = list(string)
    launch_template = object({
      id      = string
      version = string
    })
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    labels = map(string)
    tags   = map(string)
  }))
  default = {}
}

variable "fargate_profiles" {
  description = "Map of EKS Fargate profile configurations"
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = map(string)
    }))
    tags = map(string)
  }))
  default = {}
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    addon_version            = string
    resolve_conflicts        = string
    service_account_role_arn = string
    tags                     = map(string)
  }))
  default = {}
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "create_additional_iam_policies" {
  description = "Create additional IAM policies for enhanced functionality"
  type        = bool
  default     = true
}

variable "create_aws_load_balancer_controller_role" {
  description = "Create IAM role for AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "create_ebs_csi_driver_role" {
  description = "Create IAM role for EBS CSI Driver"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

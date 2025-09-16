# Basic EKS Cluster Example

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for existing VPC and subnets
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  count = var.create_vpc ? 0 : 1
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing[0].id]
  }
  
  tags = {
    Type = "private"
  }
}

data "aws_subnets" "public" {
  count = var.create_vpc ? 0 : 1
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing[0].id]
  }
  
  tags = {
    Type = "public"
  }
}

# Simple VPC for demo (optional)
module "vpc" {
  count   = var.create_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# EKS Cluster
module "eks_cluster" {
  source = "../../"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  subnet_ids = var.create_vpc ? module.vpc[0].public_subnets : data.aws_subnets.public[0].ids
  private_subnet_ids = var.create_vpc ? module.vpc[0].private_subnets : data.aws_subnets.private[0].ids

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs

  node_groups = {
    main = {
      instance_types               = var.node_instance_types
      capacity_type                = var.node_capacity_type
      disk_size                    = var.node_disk_size
      ami_type                     = "AL2_x86_64"
      desired_size                 = var.node_desired_size
      max_size                     = var.node_max_size
      min_size                     = var.node_min_size
      max_unavailable_percentage   = 25
      key_name                     = var.key_name
      source_security_group_ids    = []
      launch_template              = null
      taints                       = []
      labels = {
        Environment = var.environment
      }
      tags = {
        Environment = var.environment
      }
    }
  }

  cluster_addons = {
    coredns = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    kube-proxy = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    vpc-cni = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
  }

  enable_irsa = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

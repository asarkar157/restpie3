# EKS Cluster Terraform Module

This Terraform module creates an Amazon EKS (Elastic Kubernetes Service) cluster with associated IAM roles, policies, and optional components like node groups, Fargate profiles, and add-ons.

## Features

- **EKS Cluster**: Creates a fully managed Kubernetes cluster
- **IAM Roles & Policies**: Comprehensive IAM setup for cluster, node groups, and Fargate
- **Node Groups**: Managed EC2 instances for running workloads
- **Fargate Profiles**: Serverless compute for pods
- **IRSA Support**: IAM Roles for Service Accounts integration
- **Add-ons**: Support for EKS add-ons (VPC CNI, CoreDNS, kube-proxy, etc.)
- **Logging**: CloudWatch logging for control plane components
- **Security**: Encryption at rest and comprehensive security groups
- **Load Balancer Controller**: Optional AWS Load Balancer Controller IAM role
- **EBS CSI Driver**: Optional EBS CSI Driver IAM role

## Usage

### Basic Example

```hcl
module "eks_cluster" {
  source = "./modules/eks-cluster"

  cluster_name = "my-eks-cluster"
  subnet_ids   = ["subnet-12345", "subnet-67890"]
  
  node_groups = {
    main = {
      instance_types               = ["t3.medium"]
      capacity_type                = "ON_DEMAND"
      disk_size                    = 20
      ami_type                     = "AL2_x86_64"
      desired_size                 = 2
      max_size                     = 4
      min_size                     = 1
      max_unavailable_percentage   = 25
      key_name                     = null
      source_security_group_ids    = []
      launch_template              = null
      taints                       = []
      labels                       = {}
      tags                         = {}
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Example with Fargate and Add-ons

```hcl
module "eks_cluster" {
  source = "./modules/eks-cluster"

  cluster_name                = "advanced-eks-cluster"
  kubernetes_version          = "1.28"
  subnet_ids                  = ["subnet-12345", "subnet-67890"]
  private_subnet_ids          = ["subnet-private1", "subnet-private2"]
  
  # API endpoint configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["10.0.0.0/8"]

  # Logging configuration
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30

  # Node groups
  node_groups = {
    system = {
      instance_types               = ["t3.medium"]
      capacity_type                = "ON_DEMAND"
      disk_size                    = 20
      ami_type                     = "AL2_x86_64"
      desired_size                 = 2
      max_size                     = 4
      min_size                     = 1
      max_unavailable_percentage   = 25
      key_name                     = "my-key-pair"
      source_security_group_ids    = []
      launch_template              = null
      taints = [
        {
          key    = "node-type"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      ]
      labels = {
        "node-type" = "system"
      }
      tags = {
        "NodeGroup" = "system"
      }
    }
    
    application = {
      instance_types               = ["t3.large"]
      capacity_type                = "SPOT"
      disk_size                    = 50
      ami_type                     = "AL2_x86_64"
      desired_size                 = 3
      max_size                     = 10
      min_size                     = 1
      max_unavailable_percentage   = 33
      key_name                     = null
      source_security_group_ids    = []
      launch_template              = null
      taints                       = []
      labels = {
        "node-type" = "application"
      }
      tags = {
        "NodeGroup" = "application"
      }
    }
  }

  # Fargate profiles
  fargate_profiles = {
    default = {
      selectors = [
        {
          namespace = "default"
          labels    = {}
        },
        {
          namespace = "kube-system"
          labels = {
            "k8s-app" = "kube-dns"
          }
        }
      ]
      tags = {
        "FargateProfile" = "default"
      }
    }
  }

  # Add-ons
  cluster_addons = {
    coredns = {
      addon_version            = "v1.10.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    kube-proxy = {
      addon_version            = "v1.28.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    vpc-cni = {
      addon_version            = "v1.14.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.23.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
  }

  # IRSA and additional roles
  enable_irsa                              = true
  create_aws_load_balancer_controller_role = true
  create_ebs_csi_driver_role              = true

  tags = {
    Environment = "production"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

### Example for RESTPie3 Application

```hcl
# VPC and networking (assumed to exist)
data "aws_vpc" "main" {
  tags = {
    Name = "main-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "public"
  }
}

# EKS Cluster for RESTPie3
module "restpie3_eks" {
  source = "./modules/eks-cluster"

  cluster_name       = "restpie3-cluster"
  kubernetes_version = "1.28"
  
  subnet_ids         = data.aws_subnets.public.ids
  private_subnet_ids = data.aws_subnets.private.ids

  # Security configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]  # Restrict this in production

  # Node group for RESTPie3 application
  node_groups = {
    restpie3_nodes = {
      instance_types               = ["t3.medium"]
      capacity_type                = "ON_DEMAND"
      disk_size                    = 20
      ami_type                     = "AL2_x86_64"
      desired_size                 = 2
      max_size                     = 5
      min_size                     = 1
      max_unavailable_percentage   = 25
      key_name                     = null
      source_security_group_ids    = []
      launch_template              = null
      taints                       = []
      labels = {
        "app" = "restpie3"
      }
      tags = {
        "Application" = "restpie3"
      }
    }
  }

  # Essential add-ons
  cluster_addons = {
    vpc-cni = {
      addon_version            = "v1.14.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    coredns = {
      addon_version            = "v1.10.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    kube-proxy = {
      addon_version            = "v1.28.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.23.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
      tags                     = {}
    }
  }

  # Enable IRSA for service accounts
  enable_irsa                              = true
  create_aws_load_balancer_controller_role = true
  create_ebs_csi_driver_role              = true

  tags = {
    Environment = "production"
    Application = "restpie3"
    ManagedBy   = "terraform"
  }
}

# Outputs for use in other modules
output "eks_cluster_endpoint" {
  value = module.restpie3_eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.restpie3_eks.cluster_id
}

output "eks_cluster_certificate_authority_data" {
  value = module.restpie3_eks.cluster_certificate_authority_data
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where the EKS cluster will be deployed | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| private_subnet_ids | List of private subnet IDs for node groups and Fargate profiles | `list(string)` | `[]` | no |
| endpoint_private_access | Enable private API server endpoint | `bool` | `false` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| cluster_log_types | List of control plane logging types to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| node_groups | Map of EKS node group configurations | `map(object)` | `{}` | no |
| fargate_profiles | Map of EKS Fargate profile configurations | `map(object)` | `{}` | no |
| cluster_addons | Map of cluster addon configurations to enable for the cluster | `map(object)` | `{}` | no |
| enable_irsa | Enable IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| create_aws_load_balancer_controller_role | Create IAM role for AWS Load Balancer Controller | `bool` | `false` | no |
| create_ebs_csi_driver_role | Create IAM role for EBS CSI Driver | `bool` | `false` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for your Kubernetes API server |
| cluster_version | The Kubernetes version for the cluster |
| cluster_security_group_id | Cluster security group that was created by Amazon EKS for the cluster |
| cluster_iam_role_arn | IAM role ARN associated with EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |
| cluster_oidc_issuer_url | The URL on the EKS cluster for the OpenID Connect identity provider |
| oidc_provider_arn | The ARN of the OIDC Provider if `enable_irsa = true` |
| node_groups | Map of attribute maps for all EKS node groups created |
| fargate_profiles | Map of attribute maps for all EKS Fargate profiles created |
| aws_load_balancer_controller_role_arn | IAM role ARN for AWS Load Balancer Controller |
| ebs_csi_driver_role_arn | IAM role ARN for EBS CSI Driver |

## Post-Deployment Steps

After deploying the EKS cluster, you'll need to:

1. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

2. **Install AWS Load Balancer Controller** (if enabled):
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=<cluster-name> \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller
   ```

3. **Configure EBS CSI Driver** (if enabled):
   ```bash
   kubectl annotate serviceaccount ebs-csi-controller-sa \
     -n kube-system \
     eks.amazonaws.com/role-arn=<ebs-csi-driver-role-arn>
   ```

## Security Considerations

- Always use private subnets for node groups and Fargate profiles
- Restrict `public_access_cidrs` to your organization's IP ranges
- Enable cluster logging and monitor CloudWatch logs
- Use IAM roles for service accounts (IRSA) instead of storing AWS credentials in pods
- Regularly update Kubernetes version and add-on versions
- Implement network policies for pod-to-pod communication control

## Cost Optimization

- Use Spot instances for non-critical workloads
- Implement cluster autoscaler for dynamic scaling
- Use Fargate for workloads with unpredictable traffic patterns
- Monitor and right-size your node groups based on actual usage
- Enable container insights for better resource utilization visibility

## License

This module is released under the MIT License. See LICENSE file for details.

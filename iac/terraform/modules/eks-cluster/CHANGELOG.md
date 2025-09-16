# Changelog

All notable changes to this EKS Cluster Terraform module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-09-15

### Added
- Initial release of EKS Cluster Terraform module
- Complete EKS cluster provisioning with managed node groups
- Comprehensive IAM roles and policies for EKS, node groups, and Fargate
- Support for Fargate profiles for serverless workloads
- EKS add-ons support (VPC CNI, CoreDNS, kube-proxy, EBS CSI driver)
- IAM Roles for Service Accounts (IRSA) integration
- CloudWatch logging for EKS control plane
- Security groups and network configuration
- Encryption at rest support
- Auto-scaling configuration for node groups
- Multiple node groups with different configurations
- Spot and On-Demand instance support
- Taints and labels for workload scheduling
- Launch template support for advanced node configuration

### Features
- **EKS Cluster**: Fully managed Kubernetes cluster with configurable version
- **Node Groups**: Managed EC2 instances with auto-scaling capabilities
- **Fargate Profiles**: Serverless compute for pods
- **IAM Integration**: Comprehensive IAM setup with least privilege access
- **Add-ons Management**: Support for essential EKS add-ons
- **Security**: Network isolation, encryption, and security best practices
- **Monitoring**: CloudWatch integration for logging and monitoring
- **Flexibility**: Highly configurable with sensible defaults

### Documentation
- Comprehensive README with usage examples
- Basic example configuration
- Advanced configuration examples
- Security best practices documentation
- Testing guide and automated test suite
- Variable and output documentation

### Testing
- Automated test suite with comprehensive validation
- Terraform formatting and validation tests
- Security best practices validation
- Documentation completeness checks
- Example configuration testing

### Examples
- Basic EKS cluster example with VPC creation
- Advanced configuration with multiple node groups and Fargate
- RESTPie3 application-specific configuration example
- Production-ready configuration templates

## [Unreleased]

### Planned
- Support for EKS managed add-ons configuration
- Enhanced security group rules customization
- Additional IAM roles for common workloads (Cluster Autoscaler, etc.)
- Helm chart deployment examples
- Multi-region deployment patterns
- Cost optimization recommendations

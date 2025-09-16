# EKS Cluster Module Testing Guide

This document provides comprehensive testing instructions for the EKS Cluster Terraform module.

## Quick Test

Run the automated test suite:

```bash
./test.sh
```

## Manual Testing Steps

### 1. Prerequisites

Ensure you have the following tools installed:

- **Terraform** >= 1.0
- **AWS CLI** (optional, for deployment testing)
- **kubectl** (optional, for post-deployment testing)

### 2. Syntax and Validation Tests

```bash
# Format check
terraform fmt -check -diff

# Initialize and validate
terraform init
terraform validate

# Test basic example
cd examples/basic
terraform init
terraform validate
cd ../..
```

### 3. Security Validation

```bash
# Check for hardcoded secrets
grep -r "AKIA\|password\|secret" --include="*.tf" --include="*.tfvars" .

# Check for overly permissive CIDR blocks
grep -r "0.0.0.0/0" . --include="*.tf"
```

### 4. Documentation Validation

- ✅ README.md exists and is comprehensive
- ✅ All variables have descriptions
- ✅ All outputs have descriptions
- ✅ Examples are provided and functional
- ✅ Usage instructions are clear

### 5. Real Deployment Test (Optional)

**⚠️ Warning: This will create real AWS resources and incur costs!**

```bash
cd examples/basic

# Configure AWS credentials
aws configure

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan deployment
terraform plan

# Deploy (only if you want to test with real resources)
terraform apply

# Clean up (important!)
terraform destroy
```

## Test Results Checklist

- [ ] ✅ Terraform formatting passes
- [ ] ✅ Terraform validation passes
- [ ] ✅ Basic example validates successfully
- [ ] ✅ No hardcoded secrets detected
- [ ] ✅ Security warnings are present for permissive CIDR blocks
- [ ] ✅ All variables have descriptions
- [ ] ✅ All outputs have descriptions
- [ ] ✅ Provider versions are properly constrained
- [ ] ✅ Module structure follows best practices
- [ ] ✅ Documentation is complete and accurate

## Common Issues and Solutions

### Issue: Provider version conflicts
**Solution**: Ensure all modules use compatible provider versions

### Issue: Authentication errors during plan
**Solution**: This is expected when testing without valid AWS credentials

### Issue: VPC module version conflicts
**Solution**: Use compatible versions (e.g., `~> 5.0` for AWS provider `~> 5.0`)

## Performance Testing

For production deployments, consider testing:

1. **Cluster creation time**: Typically 10-15 minutes
2. **Node group scaling**: Test auto-scaling behavior
3. **Add-on installation**: Verify all add-ons install correctly
4. **IRSA functionality**: Test service account role assumptions

## Security Testing

1. **IAM permissions**: Verify least privilege access
2. **Network security**: Confirm private subnets for worker nodes
3. **Encryption**: Test encryption at rest functionality
4. **RBAC**: Verify Kubernetes RBAC integration

## Integration Testing

Test the module with:

1. **Different AWS regions**
2. **Various instance types**
3. **Multiple node groups**
4. **Fargate profiles**
5. **Different Kubernetes versions**

## Automated Testing in CI/CD

Example GitHub Actions workflow:

```yaml
name: Test EKS Module
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
          
      - name: Run Tests
        run: |
          cd iac/terraform/modules/eks-cluster
          ./test.sh
```

## Pre-Publication Checklist

Before publishing this module:

- [ ] All tests pass
- [ ] Documentation is complete
- [ ] Examples work correctly
- [ ] Security best practices are followed
- [ ] Version constraints are appropriate
- [ ] CHANGELOG.md is updated (if applicable)
- [ ] Module follows semantic versioning
- [ ] License file is present

## Post-Publication Testing

After publishing:

1. Test module installation from registry
2. Verify examples work with published version
3. Test with different Terraform versions
4. Validate documentation renders correctly

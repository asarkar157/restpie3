#!/bin/bash

# EKS Cluster Terraform Module Test Script
# This script performs comprehensive testing of the EKS module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    if ! command_exists aws; then
        print_warning "AWS CLI is not installed - some tests will be skipped"
    fi
    
    print_success "Prerequisites check completed"
}

# Test 1: Terraform formatting
test_formatting() {
    print_status "Testing Terraform formatting..."
    
    if terraform fmt -check -diff; then
        print_success "All files are properly formatted"
    else
        print_error "Some files need formatting. Run 'terraform fmt' to fix."
        return 1
    fi
}

# Test 2: Terraform validation
test_validation() {
    print_status "Testing Terraform validation..."
    
    # Clean any existing state
    rm -rf .terraform .terraform.lock.hcl
    
    if terraform init -backend=false; then
        print_success "Terraform initialization successful"
    else
        print_error "Terraform initialization failed"
        return 1
    fi
    
    if terraform validate; then
        print_success "Terraform validation successful"
    else
        print_error "Terraform validation failed"
        return 1
    fi
}

# Test 3: Basic example validation
test_basic_example() {
    print_status "Testing basic example..."
    
    cd examples/basic
    
    # Clean any existing state
    rm -rf .terraform .terraform.lock.hcl
    
    if terraform init -backend=false; then
        print_success "Basic example initialization successful"
    else
        print_error "Basic example initialization failed"
        cd ../..
        return 1
    fi
    
    if terraform validate; then
        print_success "Basic example validation successful"
    else
        print_error "Basic example validation failed"
        cd ../..
        return 1
    fi
    
    cd ../..
}

# Test 4: Check for security best practices
test_security_practices() {
    print_status "Checking security best practices..."
    
    # Check for hardcoded secrets
    if grep -r "AKIA\|password\|secret" --include="*.tf" --include="*.tfvars" . | grep -v "description\|variable\|example"; then
        print_error "Potential hardcoded secrets found"
        return 1
    else
        print_success "No hardcoded secrets detected"
    fi
    
    # Check for overly permissive CIDR blocks in examples
    if grep -r "0.0.0.0/0" examples/ | grep -v "# Restrict this in production"; then
        print_warning "Found 0.0.0.0/0 CIDR blocks in examples - ensure they have security warnings"
    fi
    
    print_success "Security practices check completed"
}

# Test 5: Documentation completeness
test_documentation() {
    print_status "Checking documentation completeness..."
    
    # Check if README exists
    if [[ ! -f "README.md" ]]; then
        print_error "README.md not found"
        return 1
    fi
    
    # Check if examples exist
    if [[ ! -d "examples" ]]; then
        print_error "Examples directory not found"
        return 1
    fi
    
    # Check if variables are documented
    if ! grep -q "## Inputs" README.md; then
        print_warning "Input variables documentation may be missing"
    fi
    
    # Check if outputs are documented
    if ! grep -q "## Outputs" README.md; then
        print_warning "Output variables documentation may be missing"
    fi
    
    print_success "Documentation check completed"
}

# Test 6: Variable validation
test_variables() {
    print_status "Testing variable validation..."
    
    # Check if all variables have descriptions
    if grep -n "variable " variables.tf | while read -r line; do
        var_name=$(echo "$line" | sed 's/.*variable "\([^"]*\)".*/\1/')
        if ! grep -A 10 "variable \"$var_name\"" variables.tf | grep -q "description"; then
            print_error "Variable $var_name missing description"
            return 1
        fi
    done; then
        print_success "All variables have descriptions"
    else
        return 1
    fi
}

# Test 7: Output validation
test_outputs() {
    print_status "Testing output validation..."
    
    # Check if all outputs have descriptions
    if grep -n "output " outputs.tf | while read -r line; do
        output_name=$(echo "$line" | sed 's/.*output "\([^"]*\)".*/\1/')
        if ! grep -A 5 "output \"$output_name\"" outputs.tf | grep -q "description"; then
            print_error "Output $output_name missing description"
            return 1
        fi
    done; then
        print_success "All outputs have descriptions"
    else
        return 1
    fi
}

# Test 8: AWS provider version compatibility
test_provider_versions() {
    print_status "Testing provider version compatibility..."
    
    # Check if provider versions are properly constrained
    if grep -q "version.*=" versions.tf; then
        print_success "Provider versions are constrained"
    else
        print_warning "Provider versions may not be properly constrained"
    fi
}

# Test 9: Module structure validation
test_module_structure() {
    print_status "Testing module structure..."
    
    required_files=("main.tf" "variables.tf" "outputs.tf" "versions.tf" "README.md")
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file $file not found"
            return 1
        fi
    done
    
    print_success "Module structure is valid"
}

# Test 10: Dry run with mock AWS credentials (if AWS CLI available)
test_dry_run() {
    if command_exists aws; then
        print_status "Testing dry run with mock credentials..."
        
        # Set mock AWS credentials for testing
        export AWS_ACCESS_KEY_ID="mock"
        export AWS_SECRET_ACCESS_KEY="mock"
        export AWS_DEFAULT_REGION="us-west-2"
        
        cd examples/basic
        
        # Copy example tfvars
        cp terraform.tfvars.example terraform.tfvars
        
        # Try to run plan (will fail due to auth, but should validate syntax)
        if timeout 30 terraform plan -input=false 2>&1 | grep -q "Error: No valid credential sources\|Error.*authentication\|Error.*credentials"; then
            print_success "Dry run completed - authentication error expected"
        else
            print_warning "Dry run had unexpected results"
        fi
        
        # Clean up
        rm -f terraform.tfvars
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
        
        cd ../..
    else
        print_warning "Skipping dry run test - AWS CLI not available"
    fi
}

# Main test execution
main() {
    print_status "Starting EKS Terraform Module Tests"
    echo "======================================"
    
    check_prerequisites
    
    # Array to track test results
    declare -a test_results
    
    # Run all tests
    tests=(
        "test_formatting"
        "test_validation" 
        "test_basic_example"
        "test_security_practices"
        "test_documentation"
        "test_variables"
        "test_outputs"
        "test_provider_versions"
        "test_module_structure"
        "test_dry_run"
    )
    
    failed_tests=0
    
    for test in "${tests[@]}"; do
        echo ""
        if $test; then
            test_results+=("✅ $test")
        else
            test_results+=("❌ $test")
            ((failed_tests++))
        fi
    done
    
    # Print summary
    echo ""
    echo "======================================"
    print_status "Test Summary:"
    echo ""
    
    for result in "${test_results[@]}"; do
        echo "$result"
    done
    
    echo ""
    if [[ $failed_tests -eq 0 ]]; then
        print_success "All tests passed! 🎉"
        print_status "The module is ready for publication."
    else
        print_error "$failed_tests test(s) failed."
        print_status "Please fix the issues before publishing."
        exit 1
    fi
}

# Run main function
main "$@"

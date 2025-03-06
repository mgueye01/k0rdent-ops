# Platform Engineer Guide

This guide provides detailed instructions for platform engineers on how to set up, configure, and maintain the k0rdent-ops infrastructure.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Configuration Options](#configuration-options)
- [Maintenance Tasks](#maintenance-tasks)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Initial Setup

### Prerequisites

Before you begin, ensure you have the following:

1. **AWS Account**: You need an AWS account with permissions to create VPCs, EC2 instances, security groups, etc.
2. **AWS CLI**: Install and configure the AWS CLI with your credentials.
3. **Required Tools**:
   - Terraform (>= 1.0.0)
   - kubectl
   - k0sctl
   - Git
   - SSH key pair

### Repository Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/mgueye01/k0rdent-ops.git
   cd k0rdent-ops
   ```

2. Create a GitOps repository for cluster templates:
   ```bash
   # Example using GitHub CLI
   gh repo create mgueye01/k0rdent-ops/cluster-templates --public --description "Cluster templates for k0rdent-ops"
   ```

3. Update the GitOps repository URL in the configuration:
   ```bash
   # Edit the variable in infrastructure/terraform/variables.tf or set it as an environment variable
   export GITOPS_REPO_URL="https://github.com/mgueye01/k0rdent-ops/cluster-templates.git"
   ```

## Infrastructure Deployment

### Automated Deployment

The easiest way to deploy the infrastructure is using the provided deployment script:

```bash
# Set required environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
export CLUSTER_NAME="k0rdent-cluster"
export SSH_KEY_NAME="k0rdent"
export SSH_PRIVATE_KEY_PATH="~/.ssh/k0rdent"
export DEPLOY_K0RDENT="true"

# Run the deployment script
./scripts/deploy.sh
```

### Manual Deployment

If you prefer to deploy the infrastructure manually, follow these steps:

1. Create an SSH key if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/k0rdent -N "" -C "k0rdent-ops"
   aws ec2 import-key-pair --key-name k0rdent --public-key-material fileb://~/.ssh/k0rdent.pub
   ```

2. Initialize Terraform:
   ```bash
   cd infrastructure/terraform
   terraform init
   ```

3. Create a `terraform.tfvars` file:
   ```bash
   cat > terraform.tfvars <<EOF
   aws_region = "us-east-1"
   cluster_name = "k0rdent-cluster"
   controller_count = 1
   worker_count = 2
   ssh_key_name = "k0rdent"
   ssh_private_key_path = "~/.ssh/k0rdent"
   deploy_k0rdent = true
   aws_access_key_id = "your-access-key"
   aws_secret_access_key = "your-secret-key"
   gitops_repo_url = "https://github.com/mgueye01/k0rdent-ops/cluster-templates.git"
   EOF
   ```

4. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

5. Configure kubectl:
   ```bash
   export KUBECONFIG=$(terraform output -raw kubeconfig_path)
   kubectl cluster-info
   ```

## Configuration Options

### AWS Infrastructure

You can customize the AWS infrastructure by modifying the following variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region to deploy the cluster | `us-east-1` |
| `cluster_name` | Name of the k0s cluster | `k0rdent-cluster` |
| `controller_count` | Number of controller nodes | `1` |
| `worker_count` | Number of worker nodes | `2` |
| `controller_instance_type` | Instance type for controller nodes | `t3.medium` |
| `worker_instance_type` | Instance type for worker nodes | `t3.large` |
| `controller_volume_size` | Root volume size for controller nodes in GB | `50` |
| `worker_volume_size` | Root volume size for worker nodes in GB | `100` |
| `vpc_cidr` | CIDR block for the VPC | `10.0.0.0/16` |

### k0rdent Configuration

You can customize the k0rdent installation by modifying the following variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `kcm_version` | Version of k0rdent Cluster Manager to install | `0.1.0` |
| `cert_manager_version` | Version of cert-manager to install | `v1.13.2` |
| `argocd_version` | Version of ArgoCD to install | `5.51.4` |
| `argocd_admin_password` | Admin password for ArgoCD (bcrypt hash) | `$2a$10$2XqQxLg3dJQYGE6zNiYxMeIqUWj.W9hLF7XCwYw9y/ZBBf0pnqIFC` (admin) |

## Maintenance Tasks

### Updating k0s

To update the k0s version:

1. Update the `k0s_version` variable in `infrastructure/terraform/aws/variables.tf`.
2. Apply the changes:
   ```bash
   cd infrastructure/terraform
   terraform apply
   ```

### Updating k0rdent

To update the k0rdent version:

1. Update the `kcm_version` variable in `infrastructure/terraform/k0rdent/variables.tf`.
2. Apply the changes:
   ```bash
   cd infrastructure/terraform
   terraform apply
   ```

### Scaling the Cluster

To scale the cluster:

1. Update the `controller_count` and/or `worker_count` variables.
2. Apply the changes:
   ```bash
   cd infrastructure/terraform
   terraform apply
   ```

### Backup and Restore

It's recommended to regularly backup the following:

1. Terraform state:
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

2. Kubernetes resources:
   ```bash
   kubectl get all --all-namespaces -o yaml > k8s-backup.yaml
   ```

3. ArgoCD configuration:
   ```bash
   kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml
   ```

## Troubleshooting

### Common Issues

1. **SSH Connection Issues**:
   - Ensure the SSH key exists and has the correct permissions: `chmod 600 ~/.ssh/k0rdent`
   - Verify the security group allows SSH access

2. **k0sctl Failures**:
   - Check the k0sctl logs: `k0sctl apply --config <config-path> --debug`
   - Verify the instances are running and accessible

3. **ArgoCD Issues**:
   - Check the ArgoCD pods: `kubectl get pods -n argocd`
   - Check the ArgoCD logs: `kubectl logs -n argocd <pod-name>`

4. **k0rdent Issues**:
   - Check the k0rdent pods: `kubectl get pods -n k0rdent-system`
   - Check the k0rdent logs: `kubectl logs -n k0rdent-system <pod-name>`

### Logs and Debugging

Important log locations:

- Terraform logs: Set `TF_LOG=DEBUG` before running Terraform commands
- k0s logs: `/var/log/k0s.log` on the controller nodes
- ArgoCD logs: `kubectl logs -n argocd <pod-name>`
- k0rdent logs: `kubectl logs -n k0rdent-system <pod-name>`

## Advanced Configuration

### Custom k0s Configuration

To customize the k0s configuration, modify the `k0sctl.yaml.tpl` template in `infrastructure/terraform/aws/templates/`.

### Custom k0rdent Configuration

To customize the k0rdent configuration, modify the `kcm-values.yaml.tpl` template in `infrastructure/terraform/k0rdent/templates/`.

### Custom ArgoCD Configuration

To customize the ArgoCD configuration, modify the `argocd-values.yaml.tpl` template in `infrastructure/terraform/k0rdent/templates/`.

### Using a Different Cloud Provider

The current implementation supports AWS. To add support for other cloud providers:

1. Create a new directory in `infrastructure/terraform/` for the provider (e.g., `azure`).
2. Implement the necessary Terraform configurations.
3. Update the main Terraform configuration to use the new provider.
4. Update the deployment script to support the new provider.
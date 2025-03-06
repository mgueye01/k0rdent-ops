# k0rdent-ops

Operations repository for k0rdent - A powerful tool for deploying and managing Kubernetes clusters at scale.

## Overview

k0rdent-ops is a comprehensive solution for deploying and managing Kubernetes clusters using k0s and k0rdent. It provides a seamless and automated workflow for:

1. Deploying a k0s Kubernetes cluster on AWS using Terraform
2. Installing k0rdent Cluster Manager (KCM) for multi-cluster management
3. Setting up ArgoCD for GitOps-based cluster management
4. Enabling users to create and manage clusters through pull requests

The entire process is designed to be as automated as possible, requiring minimal input from the platform engineer and providing a simple, GitOps-based workflow for users to request new clusters.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- Terraform (>= 1.0.0)
- kubectl
- k0sctl
- Git
- AWS CLI (recommended)

You will also need:

- AWS account with appropriate permissions
- AWS access key and secret key
- SSH key for accessing the instances

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/mgueye01/k0rdent-ops.git
cd k0rdent-ops
```

### 2. Deploy the Infrastructure

The deployment script will:
- Check prerequisites
- Create an SSH key if it doesn't exist
- Initialize Terraform
- Create the necessary configuration
- Deploy the infrastructure
- Configure kubectl

```bash
# Set required environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"  # Optional, defaults to us-east-1
export CLUSTER_NAME="k0rdent-cluster"  # Optional, defaults to k0rdent-cluster
export SSH_KEY_NAME="k0rdent"  # Optional, defaults to k0rdent
export SSH_PRIVATE_KEY_PATH="~/.ssh/k0rdent"  # Optional, defaults to ~/.ssh/k0rdent

# Run the deployment script
./scripts/deploy.sh
```

### 3. Create a New Cluster

Once the infrastructure is deployed, you can create new clusters using the GitOps workflow:

```bash
./scripts/create-cluster.sh
```

This script will:
- Prompt for cluster details (name, region, instance type, etc.)
- Create a cluster manifest
- Either commit and push the changes to create a pull request, or apply the manifest directly

## Architecture

### Infrastructure Components

- **AWS Infrastructure**: VPC, security groups, EC2 instances for k0s cluster
- **k0s Cluster**: Lightweight Kubernetes distribution
- **k0rdent Cluster Manager (KCM)**: For managing multiple Kubernetes clusters
- **ArgoCD**: For GitOps-based cluster management

### Workflow

1. **Platform Engineer**:
   - Deploys the infrastructure using `deploy.sh`
   - Sets up the GitOps repository for cluster templates

2. **Users**:
   - Request new clusters by creating pull requests with cluster manifests
   - Can use `create-cluster.sh` to generate the manifests and create PRs

3. **GitOps**:
   - ArgoCD watches the repository for changes
   - When a PR is merged, ArgoCD applies the changes
   - k0rdent creates and manages the requested clusters

## Directory Structure

```
k0rdent-ops/
├── docs/                   # Documentation
├── infrastructure/
│   ├── kubernetes/         # Kubernetes manifests and templates
│   │   └── templates/      # Templates for cluster creation
│   └── terraform/          # Terraform configurations
│       ├── aws/            # AWS infrastructure for k0s
│       └── k0rdent/        # k0rdent and ArgoCD installation
├── scripts/                # Automation scripts
│   ├── deploy.sh           # Infrastructure deployment script
│   └── create-cluster.sh   # Cluster creation script
└── README.md               # This file
```

## Customization

### Terraform Variables

You can customize the deployment by modifying the Terraform variables in `infrastructure/terraform/terraform.tfvars` or by setting environment variables before running `deploy.sh`.

### Cluster Templates

Cluster templates are defined in `infrastructure/kubernetes/templates/cluster-template.yaml`. You can modify this template to change the default configuration for new clusters.

## Advanced Usage

### Manual Deployment

If you prefer to deploy the infrastructure manually, you can use the following commands:

```bash
cd infrastructure/terraform
terraform init
terraform apply
```

### Accessing ArgoCD

After deployment, you can access ArgoCD using the URL and credentials provided by the deployment script. By default, the username is `admin` and the password is also `admin`.

### Troubleshooting

If you encounter issues during deployment, check the following:

- AWS credentials are correctly set
- SSH key exists and has the correct permissions
- All required tools are installed
- Network connectivity to AWS

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Acknowledgements

- [k0s](https://k0sproject.io/) - Lightweight Kubernetes distribution
- [k0rdent](https://github.com/k0rdent/kcm) - Kubernetes Cluster Manager
- [ArgoCD](https://argoproj.github.io/argo-cd/) - GitOps continuous delivery tool for Kubernetes
- [Terraform](https://www.terraform.io/) - Infrastructure as Code tool
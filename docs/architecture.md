# k0rdent-ops Architecture

This document describes the architecture of the k0rdent-ops platform, which provides a GitOps-based approach to deploying and managing k0s Kubernetes clusters.

## Overview

The k0rdent-ops platform consists of several components that work together to provide a seamless experience for both platform engineers and users:

1. **AWS Infrastructure**: The underlying cloud infrastructure where clusters are deployed
2. **k0s Kubernetes Cluster**: The management cluster that hosts k0rdent and ArgoCD
3. **k0rdent Cluster Manager**: The controller that manages the lifecycle of k0s clusters
4. **ArgoCD**: The GitOps engine that monitors the Git repository for changes
5. **GitOps Repository**: The Git repository that contains cluster definitions

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                                  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   Management VPC                            │    │
│  │                                                             │    │
│  │  ┌─────────────┐      ┌─────────────┐     ┌─────────────┐  │    │
│  │  │ Controller  │      │   Worker    │     │   Worker    │  │    │
│  │  │    Node     │      │    Node     │     │    Node     │  │    │
│  │  │             │      │             │     │             │  │    │
│  │  │  ┌─────────┐│      │ ┌─────────┐ │     │ ┌─────────┐ │  │    │
│  │  │  │   k0s   ││      │ │   k0s   │ │     │ │   k0s   │ │  │    │
│  │  │  └─────────┘│      │ └─────────┘ │     │ └─────────┘ │  │    │
│  │  │             │      │             │     │             │  │    │
│  │  └─────────────┘      └─────────────┘     └─────────────┘  │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                     Managed VPC 1                           │    │
│  │                                                             │    │
│  │  ┌─────────────┐      ┌─────────────┐     ┌─────────────┐  │    │
│  │  │ Controller  │      │   Worker    │     │   Worker    │  │    │
│  │  │    Node     │      │    Node     │     │    Node     │  │    │
│  │  │             │      │             │     │             │  │    │
│  │  │  ┌─────────┐│      │ ┌─────────┐ │     │ ┌─────────┐ │  │    │
│  │  │  │   k0s   ││      │ │   k0s   │ │     │ │   k0s   │ │  │    │
│  │  │  └─────────┘│      │ └─────────┘ │     │ └─────────┘ │  │    │
│  │  │             │      │             │     │             │  │    │
│  │  └─────────────┘      └─────────────┘     └─────────────┘  │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                     Managed VPC 2                           │    │
│  │                                                             │    │
│  │  ┌─────────────┐      ┌─────────────┐     ┌─────────────┐  │    │
│  │  │ Controller  │      │   Worker    │     │   Worker    │  │    │
│  │  │    Node     │      │    Node     │     │    Node     │  │    │
│  │  │             │      │             │     │             │  │    │
│  │  │  ┌─────────┐│      │ ┌─────────┐ │     │ ┌─────────┐ │  │    │
│  │  │  │   k0s   ││      │ │   k0s   │ │     │ │   k0s   │ │  │    │
│  │  │  └─────────┘│      │ └─────────┘ │     │ └─────────┘ │  │    │
│  │  │             │      │             │     │             │  │    │
│  │  └─────────────┘      └─────────────┘     └─────────────┘  │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

                            │
                            │
                            ▼

┌─────────────────────────────────────────────────────────────────────┐
│                      Management Cluster                             │
│                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐  │
│  │                 │    │                 │    │                 │  │
│  │     ArgoCD      │    │    k0rdent      │    │  Cert-Manager   │  │
│  │                 │    │                 │    │                 │  │
│  └─────────────────┘    └─────────────────┘    └──��──────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

                            │
                            │
                            ▼

┌─────────────────────────────────────────────────────────────────────┐
│                      GitOps Repository                              │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                             │    │
│  │  clusters/                                                  │    │
│  │  ├── dev-cluster-01.yaml                                    │    │
│  │  ├── prod-cluster-01.yaml                                   │    │
│  │  └── ...                                                    │    │
│  │                                                             │    │
│  │  templates/                                                 │    │
│  │  └── cluster-template.yaml                                  │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Details

### AWS Infrastructure

The AWS infrastructure consists of:

1. **Management VPC**: A dedicated VPC for the management cluster
   - Subnets across multiple availability zones
   - Internet Gateway for external access
   - Security Groups for controlling access

2. **Managed VPCs**: Separate VPCs for each managed cluster
   - Isolated network environments for each cluster
   - Can be configured with or without public IPs
   - Security Groups tailored to each cluster's needs

3. **EC2 Instances**: Virtual machines that run the Kubernetes nodes
   - Controller nodes: Run the Kubernetes control plane
   - Worker nodes: Run the workloads
   - Configured with appropriate instance types and storage

4. **Load Balancers**: For exposing Kubernetes API and services
   - Network Load Balancer for the Kubernetes API
   - Application Load Balancer for ingress controllers

5. **IAM Roles and Policies**: For controlling access to AWS resources
   - Instance profiles for EC2 instances
   - Service accounts for Kubernetes pods

### k0s Kubernetes Cluster

The management cluster is a k0s Kubernetes cluster that:

1. Runs on AWS EC2 instances
2. Is deployed using k0sctl
3. Provides a lightweight and easy-to-manage Kubernetes platform
4. Serves as the control plane for managing other clusters

### k0rdent Cluster Manager

k0rdent is a Kubernetes operator that:

1. Defines Custom Resource Definitions (CRDs) for clusters
2. Watches for changes to cluster resources
3. Provisions and configures k0s clusters based on the specifications
4. Manages the lifecycle of clusters (create, update, delete)
5. Provides status and health information for clusters

### ArgoCD

ArgoCD is a GitOps continuous delivery tool that:

1. Monitors the GitOps repository for changes
2. Synchronizes the desired state from Git with the actual state in Kubernetes
3. Provides a web UI for visualizing the synchronization status
4. Manages applications across multiple clusters
5. Supports automated and manual synchronization

### GitOps Repository

The GitOps repository is a Git repository that:

1. Contains the desired state of all clusters
2. Uses a declarative approach to define clusters
3. Provides version control for cluster configurations
4. Enables collaboration through pull requests
5. Serves as the single source of truth for the platform

## Workflow

The k0rdent-ops platform follows a GitOps workflow:

1. **Platform Engineer Setup**:
   - Deploy the management infrastructure using Terraform
   - Install k0s on the management cluster
   - Deploy k0rdent and ArgoCD
   - Configure ArgoCD to watch the GitOps repository

2. **User Cluster Creation**:
   - User creates a new branch in the GitOps repository
   - User copies the cluster template and customizes it
   - User submits a pull request
   - Platform engineer reviews and approves the pull request
   - ArgoCD detects the change and applies it
   - k0rdent creates the new cluster
   - User receives access to the new cluster

3. **Cluster Updates**:
   - User creates a new branch in the GitOps repository
   - User modifies the cluster configuration
   - User submits a pull request
   - Platform engineer reviews and approves the pull request
   - ArgoCD detects the change and applies it
   - k0rdent updates the cluster
   - User receives notification of the update

4. **Cluster Deletion**:
   - User creates a new branch in the GitOps repository
   - User removes the cluster configuration
   - User submits a pull request
   - Platform engineer reviews and approves the pull request
   - ArgoCD detects the change and applies it
   - k0rdent deletes the cluster
   - User receives notification of the deletion

## Security Considerations

The k0rdent-ops platform includes several security measures:

1. **Network Isolation**:
   - Each cluster runs in its own VPC
   - Security groups control access between VPCs
   - Private subnets for nodes that don't need direct internet access

2. **Access Control**:
   - IAM roles and policies for AWS resources
   - RBAC for Kubernetes resources
   - Git repository access control for cluster definitions

3. **Encryption**:
   - TLS for all API communications
   - Encrypted storage for sensitive data
   - Encrypted communication between nodes

4. **Audit Logging**:
   - AWS CloudTrail for AWS API calls
   - Kubernetes audit logging for cluster operations
   - Git history for configuration changes

## Scalability

The k0rdent-ops platform is designed to scale:

1. **Horizontal Scaling**:
   - Add more worker nodes to clusters as needed
   - Add more clusters as needed
   - Distribute clusters across regions

2. **Vertical Scaling**:
   - Increase instance sizes for nodes
   - Increase storage capacity for nodes

3. **Management Scaling**:
   - ArgoCD can manage hundreds of applications
   - k0rdent can manage dozens of clusters
   - GitOps repository can handle thousands of configurations

## High Availability

The k0rdent-ops platform provides high availability through:

1. **Multi-AZ Deployment**:
   - Nodes distributed across multiple availability zones
   - Load balancers spanning multiple availability zones

2. **Control Plane Redundancy**:
   - Multiple controller nodes for the management cluster
   - Multiple controller nodes for managed clusters (optional)

3. **Stateful Component Redundancy**:
   - etcd clustering for Kubernetes state
   - Database replication for ArgoCD

## Monitoring and Observability

The k0rdent-ops platform includes monitoring and observability:

1. **Metrics**:
   - Prometheus for collecting metrics
   - Grafana for visualizing metrics
   - AlertManager for alerting on metrics

2. **Logging**:
   - Loki for collecting logs
   - Grafana for visualizing logs

3. **Tracing**:
   - Jaeger for distributed tracing (optional)

4. **Dashboards**:
   - Kubernetes dashboard for cluster overview
   - ArgoCD dashboard for GitOps status
   - k0rdent dashboard for cluster management

## Disaster Recovery

The k0rdent-ops platform includes disaster recovery capabilities:

1. **Backup**:
   - etcd snapshots for Kubernetes state
   - Velero for Kubernetes resources
   - Git repository for configuration

2. **Restore**:
   - Restore from etcd snapshots
   - Restore from Velero backups
   - Recreate from Git repository

3. **Multi-Region**:
   - Deploy clusters across multiple regions
   - Replicate data across regions

## Conclusion

The k0rdent-ops platform provides a comprehensive solution for deploying and managing k0s Kubernetes clusters using a GitOps approach. It combines the simplicity of k0s, the power of Kubernetes operators, and the reliability of GitOps to provide a seamless experience for both platform engineers and users.
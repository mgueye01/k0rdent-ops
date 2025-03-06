# User Guide: Creating and Managing Clusters

This guide provides instructions for users who want to create and manage Kubernetes clusters using the k0rdent-ops GitOps workflow.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Creating a New Cluster](#creating-a-new-cluster)
- [Monitoring Cluster Status](#monitoring-cluster-status)
- [Accessing Your Cluster](#accessing-your-cluster)
- [Modifying Cluster Configuration](#modifying-cluster-configuration)
- [Deleting a Cluster](#deleting-a-cluster)
- [Troubleshooting](#troubleshooting)

## Introduction

The k0rdent-ops platform allows you to create and manage Kubernetes clusters using a GitOps workflow. This means that you define your cluster configuration in a Git repository, and the platform automatically provisions and configures the cluster based on that definition.

Key benefits of this approach:
- **Declarative**: Define what you want, not how to get it
- **Version-controlled**: All changes are tracked in Git
- **Automated**: Clusters are provisioned and configured automatically
- **Self-service**: Create and manage clusters without requiring platform team intervention

## Prerequisites

Before you begin, ensure you have:

1. **Git**: Installed on your local machine
2. **GitHub account**: With access to the cluster templates repository
3. **kubectl**: To interact with your clusters once created
4. **Access credentials**: Provided by your platform team

## Creating a New Cluster

### Using the Automated Script

The easiest way to create a new cluster is using the provided script:

```bash
./scripts/create-cluster.sh
```

The script will:
1. Prompt you for cluster details (name, region, size, etc.)
2. Create a cluster manifest based on your inputs
3. Submit a pull request to the GitOps repository
4. Notify you when the cluster is ready

### Manual Cluster Creation

If you prefer to create a cluster manually:

1. Clone the cluster templates repository:
   ```bash
   git clone https://github.com/mgueye01/k0rdent-ops/cluster-templates.git
   cd cluster-templates
   ```

2. Create a new branch:
   ```bash
   git checkout -b add-cluster-<n>
   ```

3. Copy the template:
   ```bash
   cp templates/cluster-template.yaml clusters/<n>.yaml
   ```

4. Edit the cluster configuration:
   ```bash
   # Edit clusters/<n>.yaml with your preferred editor
   # Modify the following parameters:
   # - name: <cluster-name>
   # - region: <aws-region>
   # - instanceType: <instance-type>
   # - nodeCount: <number-of-nodes>
   # - k0sVersion: <k0s-version>
   ```

5. Commit and push your changes:
   ```bash
   git add clusters/<n>.yaml
   git commit -m "Add new cluster: <n>"
   git push -u origin add-cluster-<n>
   ```

6. Create a pull request on GitHub.

7. Once the pull request is approved and merged, the platform will automatically provision your cluster.

## Monitoring Cluster Status

You can monitor the status of your cluster creation:

1. Visit the ArgoCD dashboard (URL provided by your platform team)
2. Log in with your credentials
3. Find your cluster in the applications list
4. Check the synchronization status and health

Alternatively, you can use the k0rdent dashboard:

1. Visit the k0rdent dashboard (URL provided by your platform team)
2. Log in with your credentials
3. Navigate to the "Clusters" section
4. Find your cluster in the list
5. Check the status and details

## Accessing Your Cluster

Once your cluster is ready, you can access it using kubectl:

1. Download the kubeconfig file from the k0rdent dashboard:
   - Navigate to your cluster
   - Click on "Download Kubeconfig"

2. Configure kubectl to use the downloaded kubeconfig:
   ```bash
   export KUBECONFIG=/path/to/downloaded/kubeconfig
   ```

3. Verify access:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

## Modifying Cluster Configuration

To modify your cluster configuration:

1. Clone the cluster templates repository (if you haven't already):
   ```bash
   git clone https://github.com/mgueye01/k0rdent-ops/cluster-templates.git
   cd cluster-templates
   ```

2. Create a new branch:
   ```bash
   git checkout -b update-cluster-<n>
   ```

3. Edit the cluster configuration:
   ```bash
   # Edit clusters/<n>.yaml with your preferred editor
   # Modify the parameters as needed
   ```

4. Commit and push your changes:
   ```bash
   git add clusters/<n>.yaml
   git commit -m "Update cluster: <n>"
   git push -u origin update-cluster-<n>
   ```

5. Create a pull request on GitHub.

6. Once the pull request is approved and merged, the platform will automatically update your cluster.

## Deleting a Cluster

To delete a cluster:

1. Clone the cluster templates repository (if you haven't already):
   ```bash
   git clone https://github.com/mgueye01/k0rdent-ops/cluster-templates.git
   cd cluster-templates
   ```

2. Create a new branch:
   ```bash
   git checkout -b delete-cluster-<n>
   ```

3. Remove the cluster configuration file:
   ```bash
   git rm clusters/<n>.yaml
   ```

4. Commit and push your changes:
   ```bash
   git commit -m "Delete cluster: <n>"
   git push -u origin delete-cluster-<n>
   ```

5. Create a pull request on GitHub.

6. Once the pull request is approved and merged, the platform will automatically delete your cluster.

## Troubleshooting

### Common Issues

1. **Pull Request Not Being Processed**:
   - Check if the CI/CD pipeline is running
   - Verify that your YAML is correctly formatted
   - Contact the platform team if the issue persists

2. **Cluster Creation Fails**:
   - Check the ArgoCD dashboard for error messages
   - Look at the k0rdent logs for more details
   - Common causes include resource limits, networking issues, or invalid configuration

3. **Cannot Access Cluster**:
   - Verify that the cluster is fully provisioned
   - Check that your kubeconfig is correctly configured
   - Ensure your network allows access to the cluster API endpoint

4. **Cluster Not Updating After Configuration Change**:
   - Check if the pull request was merged
   - Verify that ArgoCD is syncing the changes
   - Look for error messages in the ArgoCD dashboard

### Getting Help

If you encounter issues that you cannot resolve:

1. Check the documentation for similar issues and solutions
2. Contact the platform team with:
   - Cluster name
   - Error messages
   - Steps you've already taken to troubleshoot
   - Pull request URL (if applicable)

## Advanced Usage

### Custom Cluster Templates

If the standard cluster template doesn't meet your needs, you can request a custom template from the platform team. Provide details about your specific requirements, such as:

- Special networking requirements
- Custom node configurations
- Specific Kubernetes versions
- Additional components or integrations

### Accessing Cluster Logs

To access cluster logs:

1. Use kubectl to view logs for specific pods:
   ```bash
   kubectl logs -n <namespace> <pod-name>
   ```

2. For system-level logs, contact the platform team.

### Monitoring Cluster Performance

The platform includes monitoring tools that you can access:

1. Prometheus for metrics collection
2. Grafana for visualization
3. Alertmanager for notifications

Ask your platform team for access to these tools.
# k0rdent Cluster Manager

This document provides an overview of the k0rdent Cluster Manager, its architecture, features, and how it integrates with the k0rdent-ops platform.

## What is k0rdent?

k0rdent is a Kubernetes operator that manages the lifecycle of k0s Kubernetes clusters. It provides a declarative way to define, create, update, and delete k0s clusters using Kubernetes Custom Resources.

Key features of k0rdent include:

1. **Declarative Cluster Management**: Define clusters as Kubernetes resources
2. **GitOps Integration**: Works seamlessly with GitOps tools like ArgoCD
3. **Multi-Cluster Management**: Manage multiple k0s clusters from a single control plane
4. **Lifecycle Management**: Handle the entire lifecycle of clusters from creation to deletion
5. **Status Reporting**: Provide detailed status information about managed clusters
6. **Add-on Management**: Deploy and configure common add-ons like ingress controllers and metrics servers

## Architecture

k0rdent follows the Kubernetes operator pattern and consists of several components:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Management Cluster                             │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    k0rdent Namespace                        │    │
│  │                                                             │    │
│  │  ┌─────────────────┐    ┌─────────────────┐                │    │
│  │  │                 │    │                 │                │    │
│  │  │  Controller     │    │  Webhook        │                │    │
│  │  │  Manager        │    │  Server         │                │    │
│  │  │                 │    │                 │                │    │
│  │  └─────────────────┘    └─────────────────┘                │    │
│  │                                                             │    │
│  │  ┌─────────────────┐    ┌─────────────────┐                │    │
│  │  │                 │    │                 │                │    │
│  │  │  Reconcilers    │    │  API Server     │                │    │
│  │  │                 │    │                 │                │    │
│  │  └─────────────────┘    └─────────────────┘                │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    CRDs                                     │    │
│  │                                                             │    │
│  │  ┌─────────────────┐    ┌─────────────────┐                │    │
│  │  │                 │    │                 │                │    │
│  │  │  Cluster        │    │  ClusterProfile │                │    │
│  │  │                 │    │                 │                │    │
│  │  └─────────────────┘    └─────────────────┘                │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Components

1. **Controller Manager**: The main component that runs the reconciliation loops
2. **Webhook Server**: Validates and mutates Cluster resources
3. **Reconcilers**: Implement the business logic for managing clusters
4. **API Server**: Exposes the k0rdent API
5. **Custom Resource Definitions (CRDs)**:
   - **Cluster**: Defines a k0s cluster
   - **ClusterProfile**: Defines a reusable configuration for clusters

## Custom Resources

### Cluster

The `Cluster` resource defines a k0s cluster:

```yaml
apiVersion: k0rdent.io/v1alpha1
kind: Cluster
metadata:
  name: example-cluster
  labels:
    environment: development
spec:
  region: us-east-1
  
  networking:
    vpcCidr: "10.0.0.0/16"
    publicIp: true
  
  nodes:
    controllers:
      count: 1
      instanceType: t3.medium
    
    workers:
      count: 2
      instanceType: t3.large
  
  k0s:
    version: "1.28.3+k0s.0"
  
  ssh:
    keyName: k0rdent
  
  addons:
    ingress:
      enabled: true
    metricsServer:
      enabled: true
```

### ClusterProfile

The `ClusterProfile` resource defines a reusable configuration for clusters:

```yaml
apiVersion: k0rdent.io/v1alpha1
kind: ClusterProfile
metadata:
  name: development
spec:
  k0s:
    version: "1.28.3+k0s.0"
  
  nodes:
    controllers:
      instanceType: t3.medium
    
    workers:
      instanceType: t3.large
  
  addons:
    ingress:
      enabled: true
    metricsServer:
      enabled: true
```

## Workflow

k0rdent follows a reconciliation-based workflow:

1. **Watch**: The controller watches for changes to Cluster resources
2. **Reconcile**: When a change is detected, the controller reconciles the actual state with the desired state
3. **Update**: The controller updates the status of the Cluster resource to reflect the current state
4. **Report**: The controller reports any errors or events related to the reconciliation

### Cluster Creation

When a new Cluster resource is created:

1. The webhook server validates the resource
2. The controller detects the new resource
3. The controller provisions the infrastructure (AWS EC2 instances, VPC, etc.)
4. The controller installs k0s on the instances
5. The controller configures the cluster according to the specification
6. The controller installs the specified add-ons
7. The controller updates the status of the Cluster resource

### Cluster Update

When a Cluster resource is updated:

1. The webhook server validates the changes
2. The controller detects the changes
3. The controller reconciles the changes (e.g., scaling nodes, updating k0s version)
4. The controller updates the status of the Cluster resource

### Cluster Deletion

When a Cluster resource is deleted:

1. The controller detects the deletion
2. The controller terminates the cluster
3. The controller cleans up the infrastructure
4. The controller removes the finalizer from the Cluster resource

## Integration with k0rdent-ops

k0rdent integrates with the k0rdent-ops platform in several ways:

1. **GitOps Workflow**: k0rdent works with ArgoCD to implement the GitOps workflow
2. **Infrastructure Provisioning**: k0rdent provisions the infrastructure for managed clusters
3. **Cluster Management**: k0rdent manages the lifecycle of k0s clusters
4. **Status Reporting**: k0rdent provides status information for clusters

## Installation

k0rdent is installed on the management cluster using Helm:

```bash
helm repo add k0rdent https://k0rdent.github.io/charts
helm repo update
helm install k0rdent k0rdent/k0rdent \
  --namespace k0rdent-system \
  --create-namespace \
  --values values.yaml
```

Example `values.yaml`:

```yaml
k0rdent:
  aws:
    region: us-east-1
    accessKeyId: ${AWS_ACCESS_KEY_ID}
    secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
  
  ssh:
    privateKeyPath: /etc/k0rdent/ssh/id_rsa
  
  gitops:
    repoUrl: https://github.com/mgueye01/k0rdent-ops/cluster-templates.git
    branch: main
    path: clusters
```

## Configuration

k0rdent can be configured through the Helm values:

### AWS Configuration

```yaml
k0rdent:
  aws:
    region: us-east-1
    accessKeyId: ${AWS_ACCESS_KEY_ID}
    secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
    # Optional: Use IAM roles for service accounts
    irsaEnabled: true
    # Optional: Default VPC configuration
    vpc:
      cidr: "10.0.0.0/16"
      publicSubnets:
        - "10.0.1.0/24"
        - "10.0.2.0/24"
      privateSubnets:
        - "10.0.3.0/24"
        - "10.0.4.0/24"
```

### SSH Configuration

```yaml
k0rdent:
  ssh:
    privateKeyPath: /etc/k0rdent/ssh/id_rsa
    # Optional: Username for SSH access
    username: ubuntu
    # Optional: Port for SSH access
    port: 22
```

### GitOps Configuration

```yaml
k0rdent:
  gitops:
    repoUrl: https://github.com/mgueye01/k0rdent-ops/cluster-templates.git
    branch: main
    path: clusters
    # Optional: Authentication
    auth:
      type: ssh
      sshPrivateKeyPath: /etc/k0rdent/git/id_rsa
```

## Monitoring

k0rdent exposes Prometheus metrics for monitoring:

```yaml
k0rdent:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
```

The metrics include:

- Number of managed clusters
- Reconciliation duration
- Reconciliation errors
- Cluster status

## Troubleshooting

### Common Issues

1. **Cluster Creation Fails**:
   - Check the k0rdent logs:
     ```bash
     kubectl logs -n k0rdent-system -l app.kubernetes.io/name=k0rdent-controller-manager
     ```
   - Check the cluster status:
     ```bash
     kubectl describe cluster <cluster-name>
     ```
   - Check AWS permissions

2. **Cluster Update Fails**:
   - Check if the update is supported
   - Check for conflicts with existing resources
   - Check for validation errors

3. **Cluster Deletion Hangs**:
   - Check if the finalizer is stuck
   - Check if the infrastructure is being cleaned up
   - Check for AWS resource dependencies

### Logs

k0rdent logs can be viewed using kubectl:

```bash
kubectl logs -n k0rdent-system -l app.kubernetes.io/name=k0rdent-controller-manager
```

The log level can be configured in the Helm values:

```yaml
k0rdent:
  logLevel: debug  # debug, info, warn, error
```

### Events

k0rdent generates Kubernetes events for important actions:

```bash
kubectl get events --field-selector involvedObject.kind=Cluster
```

### Status

The status of a cluster can be checked using kubectl:

```bash
kubectl get cluster <cluster-name> -o yaml
```

The status includes:

- Phase (Pending, Provisioning, Running, Updating, Deleting, Failed)
- Conditions (Ready, Provisioned, Configured)
- Node information
- Endpoint information
- Last reconciliation time

## Advanced Features

### Multi-Region Support

k0rdent supports deploying clusters in multiple AWS regions:

```yaml
apiVersion: k0rdent.io/v1alpha1
kind: Cluster
metadata:
  name: multi-region-cluster
spec:
  region: us-west-2  # Different from the default region
  # ...
```

### Custom k0s Configuration

k0rdent allows customizing the k0s configuration:

```yaml
apiVersion: k0rdent.io/v1alpha1
kind: Cluster
metadata:
  name: custom-k0s-cluster
spec:
  # ...
  k0s:
    version: "1.28.3+k0s.0"
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: ClusterConfig
      metadata:
        name: k0s
      spec:
        api:
          extraArgs:
            audit-log-path: /var/log/kubernetes/audit.log
        network:
          podCIDR: 10.244.0.0/16
          serviceCIDR: 10.96.0.0/12
```

### Custom Add-ons

k0rdent supports deploying custom add-ons:

```yaml
apiVersion: k0rdent.io/v1alpha1
kind: Cluster
metadata:
  name: custom-addons-cluster
spec:
  # ...
  addons:
    custom:
      - name: prometheus
        namespace: monitoring
        repository: https://prometheus-community.github.io/helm-charts
        chart: kube-prometheus-stack
        version: 45.27.2
        values:
          grafana:
            adminPassword: prom-operator
```

## Conclusion

k0rdent Cluster Manager is a powerful tool for managing k0s Kubernetes clusters using a GitOps approach. It provides a declarative way to define, create, update, and delete clusters, making it easy to implement infrastructure as code and continuous delivery for Kubernetes clusters.
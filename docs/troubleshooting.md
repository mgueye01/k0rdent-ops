# Troubleshooting Guide

This guide provides solutions for common issues you might encounter when deploying and managing k0s clusters with k0rdent-ops.

## Table of Contents

- [Infrastructure Deployment Issues](#infrastructure-deployment-issues)
- [k0s Cluster Issues](#k0s-cluster-issues)
- [k0rdent Issues](#k0rdent-issues)
- [ArgoCD Issues](#argocd-issues)
- [Cluster Creation Issues](#cluster-creation-issues)
- [Networking Issues](#networking-issues)
- [Common Error Messages](#common-error-messages)

## Infrastructure Deployment Issues

### Terraform Initialization Fails

**Symptoms:**
- Error message: `Error: Failed to get existing workspaces: S3 bucket does not exist`
- Error message: `Error: Failed to query available provider packages`

**Solutions:**
1. Verify AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

2. Check if the S3 bucket for Terraform state exists:
   ```bash
   aws s3 ls s3://your-terraform-state-bucket
   ```

3. Ensure you have internet connectivity to download providers:
   ```bash
   curl -I https://registry.terraform.io
   ```

4. Try clearing the Terraform cache:
   ```bash
   rm -rf .terraform
   terraform init
   ```

### Terraform Apply Fails

**Symptoms:**
- Error message: `Error: Error creating VPC: UnauthorizedOperation`
- Error message: `Error: Error launching source instance: Quota exceeded`

**Solutions:**
1. Verify AWS permissions:
   ```bash
   aws iam get-user
   ```

2. Check AWS service quotas in the AWS console or via CLI:
   ```bash
   aws service-quotas list-service-quotas --service-code ec2
   ```

3. Check for existing resources that might conflict:
   ```bash
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=k0rdent-*"
   ```

4. Try applying with detailed logging:
   ```bash
   TF_LOG=DEBUG terraform apply
   ```

## k0s Cluster Issues

### k0sctl Apply Fails

**Symptoms:**
- Error message: `Failed to connect to host`
- Error message: `Failed to install k0s binary`

**Solutions:**
1. Verify SSH connectivity:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<instance-ip>
   ```

2. Check if the instances are running:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values=k0rdent-*" --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}"
   ```

3. Verify security group rules:
   ```bash
   aws ec2 describe-security-groups --filters "Name=tag:Name,Values=k0rdent-*"
   ```

4. Try running k0sctl with debug logging:
   ```bash
   k0sctl apply --config k0sctl.yaml --debug
   ```

### k0s Service Not Starting

**Symptoms:**
- Error message: `k0s service failed to start`
- No Kubernetes API server available

**Solutions:**
1. Check k0s service status on controller nodes:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<controller-ip> "sudo systemctl status k0scontroller"
   ```

2. Check k0s logs:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<controller-ip> "sudo journalctl -u k0scontroller"
   ```

3. Check disk space:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<controller-ip> "df -h"
   ```

4. Try restarting the k0s service:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<controller-ip> "sudo systemctl restart k0scontroller"
   ```

## k0rdent Issues

### k0rdent Installation Fails

**Symptoms:**
- Error message: `Error: INSTALLATION FAILED: chart not found`
- Error message: `Error: INSTALLATION FAILED: timed out waiting for the condition`

**Solutions:**
1. Verify Helm repository:
   ```bash
   helm repo list
   helm repo update
   ```

2. Check Kubernetes API accessibility:
   ```bash
   kubectl cluster-info
   ```

3. Check for namespace issues:
   ```bash
   kubectl get namespaces
   kubectl create namespace k0rdent-system
   ```

4. Try installing with debug logging:
   ```bash
   helm install k0rdent k0rdent/k0rdent --namespace k0rdent-system --debug
   ```

### k0rdent Controller Not Running

**Symptoms:**
- k0rdent pods are in `CrashLoopBackOff` or `Error` state
- Cannot create or manage clusters

**Solutions:**
1. Check pod status:
   ```bash
   kubectl get pods -n k0rdent-system
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n k0rdent-system <pod-name>
   ```

3. Check for resource constraints:
   ```bash
   kubectl describe nodes | grep -A 5 "Allocated resources"
   ```

4. Try restarting the deployment:
   ```bash
   kubectl rollout restart deployment -n k0rdent-system k0rdent-controller-manager
   ```

## ArgoCD Issues

### ArgoCD Installation Fails

**Symptoms:**
- Error message: `Error: INSTALLATION FAILED: chart not found`
- Error message: `Error: INSTALLATION FAILED: timed out waiting for the condition`

**Solutions:**
1. Verify Helm repository:
   ```bash
   helm repo list
   helm repo update
   ```

2. Check Kubernetes API accessibility:
   ```bash
   kubectl cluster-info
   ```

3. Check for namespace issues:
   ```bash
   kubectl get namespaces
   kubectl create namespace argocd
   ```

4. Try installing with debug logging:
   ```bash
   helm install argocd argo/argo-cd --namespace argocd --debug
   ```

### Cannot Access ArgoCD UI

**Symptoms:**
- ArgoCD UI is not accessible
- Error message: `Connection refused` or `Connection timed out`

**Solutions:**
1. Check if ArgoCD pods are running:
   ```bash
   kubectl get pods -n argocd
   ```

2. Check the ArgoCD service:
   ```bash
   kubectl get svc -n argocd
   ```

3. Port-forward to access the UI locally:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

4. Check ingress configuration (if using ingress):
   ```bash
   kubectl get ingress -n argocd
   ```

### ArgoCD Application Sync Fails

**Symptoms:**
- Applications show `OutOfSync` or `SyncFailed` status
- Error message: `failed to generate manifest` or `failed to apply manifest`

**Solutions:**
1. Check application status:
   ```bash
   kubectl get applications -n argocd
   ```

2. Check application details:
   ```bash
   kubectl describe application <app-name> -n argocd
   ```

3. Check repository access:
   ```bash
   kubectl get secret -n argocd
   ```

4. Try syncing manually with debug logging:
   ```bash
   argocd app sync <app-name> --debug
   ```

## Cluster Creation Issues

### Cluster Creation PR Not Being Processed

**Symptoms:**
- Pull request is merged but no cluster is being created
- No activity in ArgoCD

**Solutions:**
1. Check if the GitOps repository is correctly configured:
   ```bash
   kubectl get secret -n argocd argocd-repo-<repo-name> -o yaml
   ```

2. Check ArgoCD application controller logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
   ```

3. Verify the cluster manifest format:
   ```bash
   kubectl get crd clusters.k0rdent.io
   ```

4. Try creating an application manually:
   ```bash
   kubectl apply -f cluster-application.yaml
   ```

### Cluster Provisioning Fails

**Symptoms:**
- Cluster status shows `Failed` or `Error`
- No nodes are being created

**Solutions:**
1. Check k0rdent controller logs:
   ```bash
   kubectl logs -n k0rdent-system -l app.kubernetes.io/name=k0rdent-controller-manager
   ```

2. Check AWS permissions:
   ```bash
   aws iam get-user
   ```

3. Check AWS service quotas:
   ```bash
   aws service-quotas list-service-quotas --service-code ec2
   ```

4. Verify the cluster manifest:
   ```bash
   kubectl get cluster <cluster-name> -o yaml
   ```

## Networking Issues

### Nodes Cannot Communicate

**Symptoms:**
- Pods stuck in `Pending` or `ContainerCreating` state
- Error message: `network is unreachable`

**Solutions:**
1. Check security group rules:
   ```bash
   aws ec2 describe-security-groups --filters "Name=tag:Name,Values=k0rdent-*"
   ```

2. Verify VPC and subnet configuration:
   ```bash
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=k0rdent-*"
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
   ```

3. Check CNI pods:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-router
   ```

4. Try restarting CNI pods:
   ```bash
   kubectl delete pods -n kube-system -l k8s-app=kube-router
   ```

### Cannot Access Services

**Symptoms:**
- Services are not accessible from outside the cluster
- Error message: `Connection refused` or `Connection timed out`

**Solutions:**
1. Check service status:
   ```bash
   kubectl get svc
   ```

2. Check if pods are running:
   ```bash
   kubectl get pods
   ```

3. Check ingress controller:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

4. Verify security group rules for the load balancer:
   ```bash
   aws ec2 describe-security-groups --filters "Name=tag:Name,Values=k0rdent-*"
   ```

## Common Error Messages

### "Error: Failed to create cluster: timeout waiting for k0s to start"

**Cause:** k0s binary installation failed or the service couldn't start.

**Solutions:**
1. Check instance connectivity:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<instance-ip>
   ```

2. Check system resources:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<instance-ip> "free -h && df -h"
   ```

3. Check k0s logs:
   ```bash
   ssh -i ~/.ssh/k0rdent ubuntu@<instance-ip> "sudo journalctl -u k0scontroller"
   ```

### "Error: Failed to apply manifest: unable to recognize"

**Cause:** CRD is not installed or the API server is not available.

**Solutions:**
1. Check if CRDs are installed:
   ```bash
   kubectl get crd
   ```

2. Check API server health:
   ```bash
   kubectl get --raw /healthz
   ```

3. Reinstall CRDs:
   ```bash
   kubectl apply -f crds/
   ```

### "Error: Failed to connect to the cluster: dial tcp: lookup <hostname>: no such host"

**Cause:** DNS resolution issue or the cluster API server is not accessible.

**Solutions:**
1. Check DNS resolution:
   ```bash
   nslookup <hostname>
   ```

2. Check if the API server is running:
   ```bash
   kubectl get pods -n kube-system -l component=kube-apiserver
   ```

3. Try using the IP address instead of hostname:
   ```bash
   kubectl --server=https://<ip>:6443 get nodes
   ```

### "Error: INSTALLATION FAILED: cannot re-use a name that is still in use"

**Cause:** A release with the same name already exists.

**Solutions:**
1. Check existing releases:
   ```bash
   helm list -A
   ```

2. Delete the existing release:
   ```bash
   helm uninstall <release-name> -n <namespace>
   ```

3. Use a different name:
   ```bash
   helm install <new-name> <chart> -n <namespace>
   ```
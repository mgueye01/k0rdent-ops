variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS
}

variable "controller_instance_type" {
  description = "Instance type for controller nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.large"
}

variable "controller_count" {
  description = "Number of controller nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
  default     = "k0rdent"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/k0rdent"
}

variable "k0s_version" {
  description = "Version of k0s to install"
  type        = string
  default     = "1.28.3+k0s.0"
}

variable "cluster_name" {
  description = "Name of the k0s cluster"
  type        = string
  default     = "k0rdent-cluster"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "k0rdent-ops"
    Environment = "management"
    Terraform   = "true"
  }
}
variable "aws_region" {
  type        = string
  description = "AWS region (e.g. eu-central-1)."
}

variable "name" {
  type        = string
  description = "Base name/prefix for all resources (VPC, EKS, etc.)."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets used by EKS nodes."
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones matching the subnet definitions."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster (e.g. 1.34)."
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for the managed node group."
}

variable "node_desired_size" {
  type        = number
  description = "Desired node count for the managed node group."
}

variable "node_min_size" {
  type        = number
  description = "Minimum node count for the managed node group."
}

variable "node_max_size" {
  type        = number
  description = "Maximum node count for the managed node group."
}

variable "node_disk_size" {
  type        = number
  description = "Disk size in GB for worker nodes."
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}

# IAM principal that receives EKS cluster-admin permissions.
# Required by EKS module v21 because it manages access_entries.
# Must be a valid IAM User or Role ARN.
variable "admin_principal_arn" {
  type        = string
  description = "IAM principal with cluster-admin privileges."
}

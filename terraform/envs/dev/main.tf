# -----------------------------------------------------
# VPC (official module v6)
# -----------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # NAT gateway for private subnets (single for demo)
  enable_nat_gateway = true
  single_nat_gateway = true

  # Required for EKS and internal DNS
  enable_dns_support   = true
  enable_dns_hostnames = true

  # For demo: public subnets get public IPs by default
  map_public_ip_on_launch = true

  # Do NOT touch AWS default VPC objects (EKS recommendation)
  manage_default_security_group = false
  manage_default_route_table    = false
  manage_default_network_acl    = false

  # Kubernetes load balancer tags (public = internet-facing)
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}-cluster" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  # Private subnets for internal load balancers / nodes
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = var.tags
}

# -----------------------------------------------------
# Default VPC security group (locked down)
# -----------------------------------------------------
resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress = []
  egress  = []

  tags = merge(
    var.tags,
    { Name = "${var.name}-default-sg" }
  )

  lifecycle {
    ignore_changes = [
      tags["Name"],
      tags_all["Name"],
    ]
  }
}

# -----------------------------------------------------
# EKS (official module v21)
# -----------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.name}-cluster"
  kubernetes_version = var.cluster_version

  # Cluster creator gets admin access
  enable_cluster_creator_admin_permissions = true

  # Demo: public endpoint enabled
  endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Managed EKS addons
  addons = {
    coredns    = {}
    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  # Managed node group (single group for demo)
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      disk_size = var.node_disk_size
    }
  }

  tags = var.tags
}

# -----------------------------------------------------
# Outputs
# -----------------------------------------------------
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded EKS cluster CA"
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs used by EKS"
  value       = module.vpc.private_subnets
}

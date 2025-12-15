# -----------------------------------------------------
# EKS (official module v21)
# -----------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  # Grant cluster-admin ONLY in dev.
  # In non-dev environments (stage/prod), access must be explicitly managed
  # via IAM access entries only (aws-auth is not used in API-only mode).
  enable_cluster_creator_admin_permissions = var.environment == "dev"

  # Authentication via EKS Access API only (modern best practice).
  # - aws-auth ConfigMap is ignored
  # - Access is managed via IAM access entries
  # - In dev, cluster creator retains admin access
  authentication_mode = "API"

  # Demo: public endpoint enabled
  endpoint_public_access  = true
  endpoint_private_access = true

  endpoint_public_access_cidrs = var.eks_public_access_cidrs

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

  # Create a dedicated KMS key (managed inside the module)
  create_kms_key = true

  # Enable encryption of Kubernetes Secrets at rest
  # (EKS control plane encryption using AWS KMS)
  encryption_config = {
    resources = ["secrets"]
  }

  # Enable EKS control plane logging for auditability and troubleshooting
  enabled_log_types = [
    "api",               # Kubernetes API server requests
    "audit",             # Audit logs for security and compliance
    "authenticator",     # Authentication-related logs
    "controllerManager", # Controller manager logs
    "scheduler",         # Scheduler decision logs
  ]

  # Managed node group (single group for demo)
  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      disk_size = var.node_disk_size

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }
    }
  }

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Allow VPC-internal traffic to NodePorts (required for EKS LoadBalancers)
#
# Explanation:
#   - AWS Load Balancers (ALB/NLB) always forward traffic to NodePort targets.
#   - NodePort values are dynamic (30000–32767), therefore ports cannot be
#     safely whitelisted individually.
#   - This rule allows ONLY VPC-internal traffic (no public exposure) to reach
#     the worker nodes on any TCP port, as required by Kubernetes networking.
#
# Best practice:
#   - This is the official and recommended security model for EKS.
#   - External access remains restricted to LB listeners (80/443).
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "nodes_allow_all_from_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  description       = "Allow traffic inside VPC to reach NodePorts"
}

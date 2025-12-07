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

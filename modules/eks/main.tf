resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = var.enabled_log_types

  tags = {
    Name = "nr-${var.project}-${var.environment}-eks"
  }
}

# Small managed node group - just for core system pods (CoreDNS, etc).
# Karpenter takes over actual workload scaling in a later step.
resource "aws_eks_node_group" "core" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "nr-${var.project}-${var.environment}-core-ng"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  ami_type       = "AL2_ARM_64"   # Graviton - cheaper + efficient
  capacity_type  = "ON_DEMAND"    # core nodes stay stable; Spot comes via Karpenter later
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "nr-${var.project}-${var.environment}-core-ng"
  }

  # Cluster must fully exist before nodes try to join it
  depends_on = [aws_eks_cluster.this]
}

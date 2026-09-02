resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption - ${var.project}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "nr-${var.project}-${var.environment}-eks-kms"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/nr-${var.project}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

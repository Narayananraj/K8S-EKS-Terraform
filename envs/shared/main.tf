provider "aws" {
  region = var.aws_region
}

# GitHub's own OIDC issuer - trusted globally, same for every GitHub repo
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bd075151e0e17548162c6c76"
  ]
}

# The role GitHub Actions will assume - trust is scoped to YOUR repo only
resource "aws_iam_role" "github_actions" {
  name = "nr-${var.project}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name = "nr-${var.project}-github-actions-role"
  }
}

# Scoped permissions - not AdministratorAccess.
# Covers exactly what our VPC/KMS/IAM/EKS modules need to create/destroy.
resource "aws_iam_role_policy" "github_actions_permissions" {
  name = "nr-${var.project}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NetworkingFullAccess"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EKSFullAccess"
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMScopedToProject"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:TagRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:CreateOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders"
        ]
        Resource = [
          "arn:aws:iam::*:role/nr-${var.project}-*",
          "arn:aws:iam::*:instance-profile/nr-${var.project}-*",
          "arn:aws:iam::*:oidc-provider/*"
        ]
      },
      {
        Sid    = "KMSFullAccess"
        Effect = "Allow"
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "StateBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
      },
      {
        Sid      = "StateLockAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Resource = var.lock_table_arn
      }
    ]
  })
}
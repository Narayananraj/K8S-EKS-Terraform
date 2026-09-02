output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node.arn
}

output "node_instance_profile_name" {
  value = aws_iam_instance_profile.eks_node.name
}

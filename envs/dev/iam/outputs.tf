output "cluster_role_arn" {
  value = module.iam.cluster_role_arn
}

output "node_role_arn" {
  value = module.iam.node_role_arn
}

output "node_instance_profile_name" {
  value = module.iam.node_instance_profile_name
}

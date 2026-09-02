output "key_arn" {
  value = aws_kms_key.eks.arn
}

output "key_id" {
  value = aws_kms_key.eks.key_id
}

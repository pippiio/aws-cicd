output "kms_key_id" {
  description = "KMS CMK used by the CI/CD module."
  value       = aws_kms_key.this.id
}

output "iam_role" {
  description = "The IAM role assumed by CI/CD pipeline."
  value       = aws_iam_role.this.id
}

output "artifact_bucket" {
  description = "The artifact bucket used by CI/CD pipeline."
  value       = aws_s3_bucket.this.id
}

output "git_connection_status" {
  description = "The status of CodeStar connections. Use web console to update pending connections."
  value       = { for k, v in aws_codestarconnections_connection.this : v.name => v.connection_status }
}

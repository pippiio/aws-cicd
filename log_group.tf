resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${local.name_prefix}cicd"
  retention_in_days = local.config.log_retention_in_days
  kms_key_id        = aws_kms_key.this.arn
  tags              = local.default_tags
}

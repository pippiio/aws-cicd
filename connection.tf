resource "aws_codestarconnections_connection" "this" {
  for_each = local.config.git_connection

  name          = "${local.name_prefix}${each.key}-git-connection"
  provider_type = each.value
  tags          = local.default_tags

  lifecycle {
    prevent_destroy = true
  }
}

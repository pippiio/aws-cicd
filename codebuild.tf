## Codepipeline Action projects

resource "aws_codebuild_project" "action" {
  for_each = toset([for k, v in local.action : v.type])

  name           = "${local.name_prefix}action_${each.key}"
  description    = "Generic codebuild project for building ${each.key} actions."
  service_role   = aws_iam_role.this.arn
  tags           = local.default_tags
  encryption_key = aws_kms_key.this.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.this.name
      stream_name = "action/${each.key}"
      status      = "ENABLED"
    }
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image                       = contains(["bootstrap"], each.key) ? "aws/codebuild/amazonlinux2-x86_64-standard:3.0" : local.build_image
    image_pull_credentials_type = contains(["bootstrap"], each.key) ? null : "SERVICE_ROLE"

    environment_variable {
      name  = "DOCKER_CLI_EXPERIMENTAL"
      value = "enabled"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec/${each.key}.yaml", {
      artifact_bucket = aws_s3_bucket.this.bucket
      kms_id          = aws_kms_key.this.id
      aws_account     = local.account_id
      aws_region      = local.region_name

      # Snippets
      assume_role_snippet = local.assume_role_snippet
      env_vars_snippet    = local.env_vars_snippet
    })
  }

  dynamic "vpc_config" {
    for_each = data.aws_vpc.this

    content {
      vpc_id             = vpc_config.value.id
      subnets            = [for s in data.aws_subnet.this : s.id]
      security_group_ids = [for sg in aws_security_group.this : sg.id]
    }
  }
}

locals {
  assume_role_snippet = templatefile("${path.module}/buildspec/snippet/assume_role.yaml", {})

  env_vars_snippet = templatefile("${path.module}/buildspec/snippet/env_vars.yaml", {
    name_prefix : local.name_prefix
  })
}
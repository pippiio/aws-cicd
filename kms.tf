data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Enable IAM User Permissions"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid       = "Allow CodeBuild CloudWatch Logs"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region_name}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/codebuild/${local.name_prefix}*"]
    }
  }
}

resource "aws_kms_key" "this" {
  description         = "KMS CMK used by ${local.name_prefix}solution."
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json
  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}kms-cmk"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name_prefix}kms-cmk"
  target_key_id = aws_kms_key.this.key_id
}

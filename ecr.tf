data "aws_iam_policy_document" "ecr" {

  statement {
    sid     = "GrantCiCdRoleFullControl"
    actions = ["ecr:*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }
  }

  statement {
    sid = "AllowCrossAccountPull"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type = "AWS"
      identifiers = setunion(
        [aws_iam_role.this.arn],
        toset([for permission in values(local.config.ecr_permissions) : "arn:aws:iam::${permission.account_id}:root" if permission.pull])
      )
    }
  }

  statement {
    sid = "AllowCrossAccountPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    principals {
      type = "AWS"
      identifiers = setunion(
        [aws_iam_role.this.arn],
        toset([for permission in values(local.config.ecr_permissions) : "arn:aws:iam::${permission.account_id}:root" if permission.push])
      )
    }
  }
}

resource "aws_ecr_repository" "this" {
  for_each = { for k, v in local.action : k => v if v.ecr }

  name                 = "${local.name_prefix}${each.value.application}-${each.value.action}"
  image_tag_mutability = "MUTABLE"
  tags                 = local.default_tags

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.this.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name
  policy     = data.aws_iam_policy_document.ecr.json
}

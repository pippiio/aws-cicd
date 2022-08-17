resource "aws_iam_role" "this" {
  name = "${local.name_prefix}cicd-role"
  tags = local.default_tags

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : [
          "codebuild.amazonaws.com",
          "codepipeline.amazonaws.com",
        ]
      },
      "Action" : "sts:AssumeRole"
    }]
  })

  managed_policy_arns = setunion(
    try(local.config.iam_role_permissions.power_user ? ["arn:aws:iam::aws:policy/PowerUserAccess"] : [], []),
    try(local.config.iam_role_permissions.managed_policies != null ? local.config.iam_role_permissions.managed_policies : [], [])
  )

  inline_policy {
    name = "cloudwatch_log_permission"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [{
        "Effect" : "Allow"
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : ["${aws_cloudwatch_log_group.this.arn}:*"]
      }]
      # "Statement" : [
      #   {
      #     "Effect" : "Allow"
      #     "Action" : [
      #       "iam:*"
      #     ],
      #     "Resource" : [
      #       "arn:aws:iam::${local.account_id}:role/*",
      #       "arn:aws:iam::${local.account_id}:policy/*",
      #       "arn:aws:ecr::${local.account_id}:instance-profile/*"
      #     ] # TODO - consider adding boundaty permissions to avoid creating a user
      #   }
      # ]
    })
  }

  permissions_boundary = try(local.config.iam_role_permissions.power_user_boundary != false ? "arn:aws:iam::aws:policy/PowerUserAccess" : null, "arn:aws:iam::aws:policy/PowerUserAccess")

  dynamic "inline_policy" {
    for_each = try(local.config.iam_role_permissions.iam_nonuser_admin == true ? [1] : [], [])

    content {
      name = "IamNonUserAdministrator"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow"
            "Action" : [
              "iam:*"
            ],
            "Resource" : [
              "arn:aws:iam::${local.account_id}:role/*",
              "arn:aws:iam::${local.account_id}:policy/*",
              "arn:aws:ecr::${local.account_id}:instance-profile/*"
            ]
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = try(local.config.iam_role_permissions.inline_policies != null ? local.config.iam_role_permissions.inline_policies : {}, {})

    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }
}

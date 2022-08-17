resource "random_pet" "this" {
  prefix = "${local.name_prefix}artifact"
  keepers = {
    account = local.account_id
    region  = local.region_name
    name    = local.name_prefix
  }
}

resource "aws_s3_bucket" "this" {
  bucket = random_pet.this.id
  tags   = local.default_tags
  # force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.this
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "artifacts"
    status = "Enabled"

    expiration {
      days = local.config.artifact_retention_in_days
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "Allow SSL Requests Only"
    effect = "Deny"
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "Deny Incorrect Encryption Header"
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
    actions = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.this.arn]
    }
  }

  statement {
    sid    = "Deny Unencrypted Object Uploads"
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
    actions = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  depends_on = [
    aws_s3_bucket.this
  ]
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_public_access_block.this
  ]
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "name_prefix" {
  description = "A prefix that will be used on all named resources."
  type        = string
  default     = "pippi-"

  validation {
    condition     = length(regexall("^[a-zA-Z-]*$", var.name_prefix)) > 0
    error_message = "`name_prefix` must satisfy pattern `^[a-zA-Z-]+$`."
  }
}

variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

locals {
  name_prefix = var.name_prefix
  default_tags = merge(var.default_tags, {
    tf-module : "pippi.io/aws-cicd"
    tf-workspace = terraform.workspace
  })

  region_name = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
}

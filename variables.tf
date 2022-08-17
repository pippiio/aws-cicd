variable "config" {
  description = ""
  type = object({
    build_image = optional(string)
    subnet_ids  = optional(set(string))

    log_retention_in_days      = optional(number)
    artifact_retention_in_days = optional(number)

    git_connection = optional(map(string))
    docker_connection = optional(object({
      username = string
      password = string
    }))

    iam_role_permissions = optional(object({
      power_user          = optional(bool)
      power_user_boundary = optional(bool)
      iam_nonuser_admin   = optional(bool)
      managed_policies    = optional(list(string))
      inline_policies     = optional(map(string))
    }))

    ecr_permissions = optional(map(object({
      account_id = string
      pull       = bool
      push       = bool
    })))
  })

  validation {
    condition = alltrue([
      for k, v in var.config.git_connection != null ? var.config.git_connection : {} : length(regexall("^[a-zA-Z-_]*$", k)) > 0
    ])
    error_message = "`config.git_connection` key is invalid. Key must satisfy pattern `^[a-zA-Z0-9-_]+$`."
  }

  validation {
    condition     = length([for k, v in var.config.git_connection != null ? var.config.git_connection : {} : k if !contains(["GitHub", "Bitbucket"], v)]) == 0
    error_message = "`config.git_connection` is invalid. Valid values are [GitHub Bitbucket]."
  }
}

variable "applications" {
  description = ""
  type = map(object({
    git_repository_url = optional(string)
    git_connection     = optional(string)
    git_trigger        = optional(map(string))
    s3_bucket          = optional(string)
    s3_trigger         = optional(map(string))
    ecr_repository     = optional(string)
    ecr_trigger        = optional(map(string))

    action = optional(map(object({
      stage       = optional(string)
      run_order   = optional(number)
      type        = string
      source      = string
      target      = optional(string)
      custom_args = optional(string)
    })))
  }))

  validation {
    condition = alltrue([for k, v in var.applications :
      length(flatten(regexall("(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git", v.git_repository_url))) == 3
    ])
    error_message = "`applications[*].git_repository_url` does not seem to be a valid github or bitbucket repository url. Must satisfy '(github.com|bitbucket.org)[:\\/]([^\\/]+)\\/([^\\/]+)\\.git'."
  }

  // todo verify works without git 
  // todo verify no duplicate triggers accross providers
}

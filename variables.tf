variable "prefix" {}
variable "common_tags" {
  type = map(string)
}

##########################
# API LAMBDA VARIABLES
##########################

variable "description" {
  default = "Codeless lambda so code CI CD can be managed externally"
}

variable "runtime" {
  default = "python3.7"
}

variable "handler" {
  default = "app.runtime.lambda.main.handler"
}

variable "memory_size" {
  default = 512
}

variable "envs" {
  type = map(string)
}

variable "policy_json" {
  type    = string
  default = null
}

variable "logs_retention_in_days" {
  default = 1
}

variable "jwt_authorization_groups_attr_name" {
  default = "groups"
}

##########################
# API GATEWAY VARIABLES
##########################

variable "stage_name" {
  type    = string
  default = "this"
}

variable "access_logs_retention_in_days" {
  type    = number
  default = 3
}

# JWT
variable "jwt_authorizer" {
  description = "JWT Authorizer Issuer/Audience (User Pool Endpoint and Client ID in case of Cognito)"
  type        = object({
    issuer   = string
    audience = list(string)
  })
}

variable "routes_definitions" {
  default = {
    health_check = {
      operation_name = "Service Health Check"
      route_key      = "GET /v1/manage/hc"
    }
    token = {
      operation_name = "Get authorization token"
      route_key      = "POST /v1/auth/token"
    }
    whoami = {
      operation_name = "Get user claims"
      route_key      = "GET /v1/users/whoami"
      # Authorization
      api_key_required     = false
      authorization_type   = "JWT"
      authorization_scopes = []
    }
    site_map = {
      operation_name = "Get endpoints list"
      route_key      = "GET /v1/admin/endpoints"
      # Authorization
      api_key_required     = false
      authorization_type   = "JWT"
      authorization_scopes = []
    }
    swagger_specification = {
      operation_name = "Swagger Specification"
      route_key      = "GET /v1/swagger.json"
    }
    swagger_ui = {
      operation_name = "Swagger UI"
      route_key      = "GET /v1/docs"
    }
  }
}

##########################
# API CI/CD VARIABLES
##########################

# Github
# --------
variable "github" {
  description = "A map of strings with GitHub specific variables"
  type        = object({
    owner          = string
    connection_arn = string
    webhook_secret = string
  })
}

variable "pre_release" {
  default = true
}

variable "github_repository" {
  type = object({
    name   = string
    branch = string
  })
}

# S3 Buckets
# ----------
variable "s3_artifacts" {
  type = object({
    bucket = string
    arn    = string
  })
}

variable "app_src_path" {}
variable "packages_descriptor_path" {}

# Notification
# ------------
variable "ci_notifications_slack_channels" {
  description = "Slack channel name for notifying ci pipeline info/alerts"
  type        = object({
    info  = string
    alert = string
  })
}

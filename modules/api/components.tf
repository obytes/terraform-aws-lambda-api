module "api" {
  source      = "git::https://github.com/obytes/terraform-aws-codeless-lambda.git//modules/lambda"
  prefix      = local.prefix
  common_tags = local.common_tags

  runtime                = var.runtime
  timeout                = 29
  memory_size            = var.memory_size
  description            = var.description
  policy_json            = var.policy_json
  logs_retention_in_days = var.logs_retention_in_days

  envs = merge(var.envs, {
    RUNTIME = "LAMBDA"

    # API
    AWS_API_GW_STAGE_NAME = var.stage_name

    # Authentication/Authorization
    JWT_AUTHORIZATION_GROUPS_ATTR_NAME = var.jwt_authorization_groups_attr_name
  })
}

module "api_ci" {
  source      = "git::https://github.com/obytes/terraform-aws-lambda-ci.git//modules/ci"
  prefix      = "${local.prefix}-ci"
  common_tags = local.common_tags

  # Lambda
  lambda                   = module.api.lambda
  app_src_path             = var.app_src_path
  packages_descriptor_path = var.packages_descriptor_path

  # Github
  s3_artifacts      = var.s3_artifacts
  github            = var.github
  pre_release       = true
  github_repository = var.github_repository

  # Notifications
  ci_notifications_slack_channels = var.ci_notifications_slack_channels
}


module "api_gw" {
  source      = "git::https://github.com/obytes/terraform-aws-lambda-apigw.git//modules/gw"
  prefix      = local.prefix
  common_tags = local.common_tags

  stage_name         = var.stage_name
  api_lambda         = module.api.lambda
  jwt_authorizer     = var.jwt_authorizer
  routes_definitions = var.routes_definitions
}

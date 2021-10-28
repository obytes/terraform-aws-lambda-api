module "aws_lambda_api" {
  source      = "./modules/api"
  prefix      = var.prefix
  common_tags = var.common_tags

  # Lambda API
  description                        = var.description
  runtime                            = var.runtime
  handler                            = var.handler
  memory_size                        = var.memory_size
  envs                               = var.envs
  policy_json                        = var.policy_json
  logs_retention_in_days             = var.logs_retention_in_days
  jwt_authorization_groups_attr_name = var.jwt_authorization_groups_attr_name

  # CI/CD
  github                          = var.github
  pre_release                     = var.pre_release
  github_repository               = var.github_repository
  s3_artifacts                    = var.s3_artifacts
  app_src_path                    = var.app_src_path
  packages_descriptor_path        = var.packages_descriptor_path
  ci_notifications_slack_channels = var.ci_notifications_slack_channels

  # API Gateway
  stage_name                    = var.stage_name
  jwt_authorizer                = var.jwt_authorizer
  routes_definitions            = var.routes_definitions
  access_logs_retention_in_days = var.access_logs_retention_in_days
}

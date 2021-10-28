# API LAMBDA
output "lambda" {
  value = module.aws_lambda_api.lambda
}

output "role" {
  value = module.aws_lambda_api.role
}

# API GW
output "http_api_id" {
  value = module.aws_lambda_api.http_api_id
}

output "http_api_stage_name" {
  value = module.aws_lambda_api.http_api_stage_name
}

# API CI
output "codebuild_project_name" {
  value = module.aws_lambda_api.codebuild_project_name
}

output "codepipeline_project_name" {
  value = module.aws_lambda_api.codepipeline_project_name
}

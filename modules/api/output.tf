# API LAMBDA
output "lambda" {
  value = module.api.lambda
}

output "role" {
  value = module.api.role
}

# API GW
output "http_api_id" {
  value = module.api_gw.http_api_id
}

output "http_api_stage_name" {
  value = module.api_gw.http_api_stage_name
}

# API CI
output "codebuild_project_name" {
  value = module.api_ci.codebuild_project_name
}

output "codepipeline_project_name" {
  value = module.api_ci.codepipeline_project_name
}

# Terraform AWS Lambda API

A Terraform reusable module for provisioning AWS Lambda API with its CI/CD and API Gateway

A Functional Lambda API consists of the followings components:

1. [Lambda API Code compatible with API Gateway](https://github.com/obytes/lambda-flask-api) - an API 
   built with any Restfull API framework like Flask API and Fast API, and able to adapt a Lambda API Gateway event into 
   an HTTP Request and HTTP Response into API Gateway Response.
  
2. [Codeless Lambda Function](https://github.com/obytes/terraform-aws-codeless-lambda) - a reusable Terraform module 
   for provisioning the Lambda resources, the code/dependencies build and deployment should be delegated to an external 
   CI/CD process.
  
3. [Lambda Function CI/CD](https://github.com/obytes/terraform-aws-lambda-ci) - a Terraform module for Lambda code and 
   dependencies continuous integration/deployment.

4. [API Gateway HTTP API](https://github.com/obytes/terraform-aws-lambda-apigw) - An API Gateway HTTP API that 
   integrates with an Upstream Lambda Function, authorize and proxy requests.

5. [API Gateway APIs Exposer](https://github.com/obytes/terraform-aws-gato) - API Gateway resources for creating custom 
   domain, mapping the domain with the API Gateway HTTP API and exposing the API through route53 or cloudflare records.
  
6. [An Identity as a Service Provider](https://github.com/obytes/terraform-aws-gato) - Any JWT compatible provider that 
   API Gateway can integrate with for authorizing requests based on users JWT access tokens.

This reusable module, can provision **Codeless Lambda Function(2)**, **Lambda Function CI/CD(3)** and 
**API Gateway HTTP API(4)**.

The **API Gateway APIs Exposer(5)** is placed in a separate module because it's more generic and it can be used to 
expose multiple API Gateway HTTP APIs(4) or even API Gateway Websocket APIs.

The **Lambda API Code compatible with API Gateway(1)** and **Identity as a Service Provider(6)** components are your 
responsibility to build and configure but a 
[Starter Boilerplate Lambda Flask Application](https://github.com/obytes/lambda-flask-api) is provided to you for 
inspiration and demo.

## Prerequisites

- A Restfull API compatible with Lambda/AWS-APIGW
- A route53 or cloudflare zone (That you own of course)
- An ACM certificate for your API Gateway custom domains
- A codestar connection to your Github account.
- An S3 bucket for holding CI/CD artifacts and Lambda Code/Dependencies
- A Firebase project (Or any other IaaS provider).
- Two Slack channels for notifying `success` adn `failure` deployments.

## Usage

1. Version Control your Lambda Function API in Github.

2. Provision Codeless Lambda Function(2), Lambda Function CI/CD(3) and API Gateway HTTP API(4).

```hcl
module "aws_lambda_api" {
  source      = "git::https://github.com/obytes/terraform-aws-lambda-api.git//modules/api"
  prefix      = "${local.prefix}-flask"
  common_tags = local.common_tags

  # Lambda API
  description                        = "Flask Lambda API"
  runtime                            = "python3.7"
  handler                            = "app.runtime.lambda.main.handler"
  memory_size                        = 512
  envs                               = {}
  policy_json                        = null
  logs_retention_in_days             = 3
  jwt_authorization_groups_attr_name = "groups"

  # CI/CD
  github                          = {
     owner          = "obytes"
     webhook_secret = "not-secret"
     connection_arn = "arn:aws:codestar-connections:us-east-1:{ACCOUNT_ID}:connection/{CONNECTION_ID}"
  }
  pre_release                     = true
  github_repository               = {
    name   = "lambda-flask-api"
    branch = "main"
  }
  s3_artifacts                    = {
     arn    = aws_s3_bucket.artifacts.arn
     bucket = aws_s3_bucket.artifacts.bucket
  }
  app_src_path                    = "src"
  packages_descriptor_path        = "src/requirements/lambda.txt"
  ci_notifications_slack_channels = {
     info  = "ci-info"
     alert = "ci-alert"
  }

  # API Gateway
  stage_name                    = "mvp"
  jwt_authorizer                = {
    issuer   = "https://securetoken.google.com/flask-lambda"
    audience = [ "flask-lambda" ]
  }
  routes_definitions            = {
    health_check = {
      operation_name = "Service Health Check"
      route_key      = "GET /v1/manage/hc"
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
  }
  access_logs_retention_in_days = 3
}
```

3. Provision The API Gateway APIs Exposer(5):

```hcl
module "gato" {
  source      = "git::https://github.com/obytes/terraform-aws-gato.git//modules/core-route53"
  prefix      = local.prefix
  common_tags = local.common_tags

  # DNS
  r53_zone_id = aws_route53_zone.prerequisite.zone_id
  cert_arn    = aws_acm_certificate.prerequisite.arn
  domain_name = "kodhive.com"
  sub_domains = {
    stateless = "api"
    statefull = "ws"
  }

  # Rest APIS
  http_apis = [
    {
      id    = module.aws_lambda_api.http_api_id
      key   = "starter"
      stage = module.aws_lambda_api.http_api_stage_name
    },
  ]
  ws_apis = []
}
```

4. Enjoy

- Public Endpoint [ALLOW]

```bash
curl -X GET https://api.kodhive.com/starter/v1/manage/hc
{
    "status": "I'm sexy and i know it"
}
```

- Private Endpoint [DENY]

```bash
curl -X GET https://api.kodhive.com/starter/v1/users/whoami
{"message":"Unauthorized"}%
```

- Private Endpoint [ALLOW]

```bash
curl -X GET https://api.kodhive.com/starter/v1/users/whoami -H "Authorization: Bearer NORMAL_USER_FIREBASE_JWT_TOKEN"
{
    "claims": {
        "aud": "flask-lambda",
        "auth_time": "1635015339",
        "email": "sanitized@gmail.com",
        "email_verified": "true",
        "exp": "1635018939",
        "firebase": "map[identities:map[email:[sanitized@gmail.com]] sign_in_provider:password]",
        "groups": "[USERS ADMINS]",
        "iat": "1635015339",
        "iss": "https://securetoken.google.com/flask-lambda",
        "name": "Hamza Adami",
        "picture": "https://siasky.net/_AlWdFnwvbHwXoDeVk-4DrMKcmQajKIJ2z-maOkXsDfYNw",
        "sub": "NcpGCnZ9B0cFDqRllYbtTYG8awE2",
        "user_id": "NcpGCnZ9B0cFDqRllYbtTYG8awE2"
    }
}
```

- Admin Endpoint [DENY]

```bash
curl -X GET https://api.kodhive.com/starter/v1/admin/endpoints -H "Authorization: Bearer NORMAL_USER_FIREBASE_JWT_TOKEN"
{
    "error": {
        "code": "002401",
        "title": "Unauthorized",
        "message": "Access unauthorized",
        "reason": "Only ['ADMINS'] can access this endpoint"
    },
    "message": "Only ['ADMINS'] can access this endpoint"
}
```

- Admin Endpoint [ALLOW]

```bash
curl -X GET https://api.kodhive.com/starter/v1/admin/endpoints -H "Authorization: Bearer ADMIN_USER_FIREBASE_JWT_TOKEN"
{
    "endpoints": [
        {
            "path": "/mvp/v1/manage/hc",
            "name": "api.manage_health_check"
        },
        {
            "path": "/mvp/v1/admin/endpoints",
            "name": "api.admin_list_endpoints"
        },
        {
            "path": "/mvp/v1/users/whoami",
            "name": "api.users_who_am_i"
        },
        {
            "path": "/mvp/v1/swagger.json",
            "name": "api.specs"
        },
        {
            "path": "/mvp/v1/docs",
            "name": "api.doc"
        },
        {
            "path": "/mvp/v1/",
            "name": "api.root"
        }
    ]
}
```

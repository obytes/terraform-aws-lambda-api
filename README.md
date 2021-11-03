# Terraform AWS Lambda API

A Terraform reusable module for provisioning AWS Lambda API with its CI/CD and API Gateway

A Functional Lambda API consists of the followings components:

1. AWS Lambda API Code compatible with API Gateway - an API built with any Restfull API framework like Flask API and
   Fast API, and able to adapt Lambda API Gateway events into HTTP Requests and HTTP Responses into API Gateway Responses.
   an [AWS Lambda Fast API Starter](https://github.com/obytes/lambda-fast-api) and
   [AWS Lambda Flask API Starter](https://github.com/obytes/lambda-flask-api) are provided.
  
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

- HTTP API application compatible with Lambda/AWS-APIGW (A starter app is provided)
- Route53 or Cloudflare zone (That you own of course)
- ACM certificate for your AWS API Gateway custom domain (For HTTPs)
- Codestar connection to your Github account.
- S3 bucket for holding CI/CD artifacts and Lambda Code/Dependencies
- Firebase project or a project in any other IaaS providers.
- Slack channel(s) for notifying `success` adn `failure` deployments.

## Usage

- Version Control your Lambda Function API in Github.

- Provision Codeless Lambda Function(2), Lambda Function CI/CD(3) and API Gateway HTTP API(4).

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
  envs                               = {
     FIREBASE_APP_API_KEY   = "AIzaSyAbiq3L6lVT9TyM_Lik6C5rgSLEGCiqJhM"
     AWS_API_GW_MAPPING_KEY = "flask"
  }
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
  access_logs_retention_in_days = 3
}
```

- For FastAPI lovers, we've got your back:

```hcl
module "aws_fast_lambda_api" {
  source      = "git::https://github.com/obytes/terraform-aws-lambda-api.git//modules/api"
  prefix      = "${local.prefix}-fast"
  common_tags = local.common_tags

  # Lambda API
  description                        = "Fast Lambda API"
  runtime                            = "python3.7"
  handler                            = "app.runtime.lambda.main.handler"
  memory_size                        = 512
  envs                               = {
    FIREBASE_APP_API_KEY   = "AIzaSyAbiq3L6lVT9TyM_Lik6C5rgSLEGCiqJhM"
    AWS_API_GW_MAPPING_KEY = "fast"
  }
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
    name   = "lambda-fast-api"
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
      operation_name = "Get site map"
      route_key      = "GET /v1/admin/endpoints"
      # Authorization
      api_key_required     = false
      authorization_type   = "JWT"
      authorization_scopes = []
    }
    openapi = {
      operation_name = "OpenAPI Specification"
      route_key      = "GET /v1/openapi.json"
    }
    swagger = {
      operation_name = "Swagger UI"
      route_key      = "GET /v1/docs"
    }
    redoc = {
      operation_name = "ReDoc UI"
      route_key      = "GET /v1/redoc"
    }
  }
  access_logs_retention_in_days = 3
}
```

- Provision The AWS API Gateway APIs Exposer(5)

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
         id    = module.aws_flask_lambda_api.http_api_id
         key   = "flask"
         stage = module.aws_flask_lambda_api.http_api_stage_name
      },
      {
         id    = module.aws_fast_lambda_api.http_api_id
         key   = "fast"
         stage = module.aws_fast_lambda_api.http_api_stage_name
      },
   ]
   ws_apis = []
}
```

With this configuration, our Lambda API Gateway final base URLs will be https://api.kodhive.com/flask/ for Flask API
and https://api.kodhive.com/fast/ for Fast API and these endpoints will be exposed:

- FlaskAPI:
   - GET https://api.kodhive.com/flask/v1/manage/hc [PUBLIC]
   - POST https://api.kodhive.com/flask/v1/auth/token [AUTH]
   - GET https://api.kodhive.com/flask/v1/users/whoami [PRIVATE]
   - GET https://api.kodhive.com/flask/v1/admin/endpoints [ADMIN]
   - GET https://api.kodhive.com/flask/v1/docs [DOCS]

![Flask Docs](/docs/images/flask-docs.png)

- FastAPI:
   - GET https://api.kodhive.com/fast/v1/manage/hc [PUBLIC]
   - POST https://api.kodhive.com/fast/v1/auth/token [AUTH]
   - GET https://api.kodhive.com/fast/v1/users/whoami [PRIVATE]
   - GET https://api.kodhive.com/fast/v1/admin/endpoints [ADMIN]
   - GET https://api.kodhive.com/fast/v1/docs [DOCS]

![Fast Docs](/docs/images/fast-docs.png)

## Demo

- Public Endpoint [ALLOW]

```bash
curl -X GET https://api.kodhive.com/flask/v1/manage/hc
{
    "status": "I'm sexy and I know It"
}
```

- Auth Endpoint [DENY]

```bash
curl -X POST -F 'username=does.not.exist@gmail.com' -F 'password=not-secret' https://api.kodhive.com/flask/v1/auth/token
{
    "error": {
        "code": "002401",
        "title": "Unauthorized",
        "message": "Access unauthorized",
        "reason": "EMAIL_NOT_FOUND"
    },
    "message": "EMAIL_NOT_FOUND"
}
```

- Auth Endpoint [ALLOW]

```bash
curl -X POST -F 'username=admin@gmail.com' -F 'password=not-secret' https://api.kodhive.com/flask/v1/auth/token
{
    "kind": "identitytoolkit#VerifyPasswordResponse",
    "localId": "gf30eciYKjVJrA5XMHK0NKDbKeC2",
    "email": "admin@gmail.com",
    "displayName": "Super Admin",
    "registered": true,
    "profilePicture": "https://img2.freepng.fr/20180402/ogw/kisspng-computer-icons-user-profile-clip-art-user-avatar-5ac208105c03d6.9558906215226654883769.jpg",
    "refreshToken": "TOO_LONG_TOKEN",
    "expiresIn": "3600",
    "token_type": "bearer",
    "access_token": "TOO_LONG_TOKEN"
}
```

- Private Endpoint [DENY]

```bash
curl -X GET https://api.kodhive.com/flask/v1/users/whoami
{"message":"Unauthorized"}%
```

- Private Endpoint [ALLOW]

```bash
curl -X GET https://api.kodhive.com/flask/v1/users/whoami -H "Authorization: Bearer NORMAL_USER_FIREBASE_JWT_TOKEN"
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
curl -X GET https://api.kodhive.com/flask/v1/admin/endpoints -H "Authorization: Bearer NORMAL_USER_FIREBASE_JWT_TOKEN"
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
curl -X GET https://api.kodhive.com/flask/v1/admin/endpoints -H "Authorization: Bearer ADMIN_USER_FIREBASE_JWT_TOKEN"
{
    "endpoints": [
        {
            "path": "/v1/manage/hc",
            "name": "api.manage_health_check"
        },
        {
            "path": "/v1/admin/endpoints",
            "name": "api.admin_list_endpoints"
        },
        {
            "path": "/v1/users/whoami",
            "name": "api.users_who_am_i"
        },
        {
            "path": "/v1/swagger.json",
            "name": "api.specs"
        },
        {
            "path": "/v1/docs",
            "name": "api.doc"
        },
        {
            "path": "/v1/",
            "name": "api.root"
        }
    ]
}
```
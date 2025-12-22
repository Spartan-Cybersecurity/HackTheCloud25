# API Gateway REST API
resource "aws_api_gateway_rest_api" "patient_api" {
  name        = "${var.project_name}-patient-api-${random_string.suffix.result}"
  description = "MediCloudX Patient Records API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-patient-api"
  })
}

# Cognito Authorizer for API Gateway
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "${var.project_name}-cognito-authorizer"
  rest_api_id           = aws_api_gateway_rest_api.patient_api.id
  type                  = "COGNITO_USER_POOLS"
  provider_arns         = [aws_cognito_user_pool.main.arn]
  identity_source       = "method.request.header.Authorization"
  authorizer_credentials = aws_iam_role.api_gateway_role.arn
}

# Lambda Authorizer for role validation
resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  name                   = "${var.project_name}-lambda-authorizer"
  rest_api_id           = aws_api_gateway_rest_api.patient_api.id
  type                  = "REQUEST"
  authorizer_uri        = aws_lambda_function.jwt_authorizer.invoke_arn
  identity_source       = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}

# API Gateway Role
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.project_name}-api-gateway-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-api-gateway-role"
  })
}

# API Gateway Policy
resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "${var.project_name}-api-gateway-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway Resource: /patients
resource "aws_api_gateway_resource" "patients" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id
  parent_id   = aws_api_gateway_rest_api.patient_api.root_resource_id
  path_part   = "patients"
}

# API Gateway Method: GET /patients
resource "aws_api_gateway_method" "get_patients" {
  rest_api_id   = aws_api_gateway_rest_api.patient_api.id
  resource_id   = aws_api_gateway_resource.patients.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# API Gateway Integration: Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.patient_api.id
  resource_id             = aws_api_gateway_resource.patients.id
  http_method             = aws_api_gateway_method.get_patients.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.read_data_patience.invoke_arn
}

# API Gateway Method Response
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id
  resource_id = aws_api_gateway_resource.patients.id
  http_method = aws_api_gateway_method.get_patients.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# API Gateway Integration Response
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id
  resource_id = aws_api_gateway_resource.patients.id
  http_method = aws_api_gateway_method.get_patients.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "options_patients" {
  rest_api_id   = aws_api_gateway_rest_api.patient_api.id
  resource_id   = aws_api_gateway_resource.patients.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id
  resource_id = aws_api_gateway_resource.patients.id
  http_method = aws_api_gateway_method.options_patients.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_response_200" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id
  resource_id = aws_api_gateway_resource.patients.id
  http_method = aws_api_gateway_method.options_patients.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id
  resource_id = aws_api_gateway_resource.patients.id
  http_method = aws_api_gateway_method.options_patients.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
  }

  depends_on = [aws_api_gateway_integration.options_integration]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "patient_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.patient_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.patients.id,
      aws_api_gateway_method.get_patients.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method.options_patients.id,
      aws_api_gateway_integration.options_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.get_patients,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method.options_patients,
    aws_api_gateway_integration.options_integration,
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "patient_api_stage" {
  deployment_id = aws_api_gateway_deployment.patient_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.patient_api.id
  stage_name    = "prod"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-patient-api-stage"
  })
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.read_data_patience.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.patient_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_authorizer" {
  statement_id  = "AllowExecutionFromAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jwt_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.patient_api.execution_arn}/authorizers/${aws_api_gateway_authorizer.lambda_authorizer.id}"
}

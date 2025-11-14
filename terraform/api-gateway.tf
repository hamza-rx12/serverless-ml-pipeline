# API Gateway REST API
resource "aws_api_gateway_rest_api" "image_analysis_api" {
  name        = "image-analysis-api"
  description = "API for image analysis frontend"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "image-analysis-api"
    Environment = var.environment
    Project     = var.project_name
  }
}

# /upload-url resource
resource "aws_api_gateway_resource" "upload_url" {
  rest_api_id = aws_api_gateway_rest_api.image_analysis_api.id
  parent_id   = aws_api_gateway_rest_api.image_analysis_api.root_resource_id
  path_part   = "upload-url"
}

# POST /upload-url method
resource "aws_api_gateway_method" "upload_url_post" {
  rest_api_id   = aws_api_gateway_rest_api.image_analysis_api.id
  resource_id   = aws_api_gateway_resource.upload_url.id
  http_method   = "POST"
  authorization = "NONE"
}

# POST /upload-url integration
resource "aws_api_gateway_integration" "upload_url_integration" {
  rest_api_id             = aws_api_gateway_rest_api.image_analysis_api.id
  resource_id             = aws_api_gateway_resource.upload_url.id
  http_method             = aws_api_gateway_method.upload_url_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_upload_url.invoke_arn
}

# /results resource
resource "aws_api_gateway_resource" "results" {
  rest_api_id = aws_api_gateway_rest_api.image_analysis_api.id
  parent_id   = aws_api_gateway_rest_api.image_analysis_api.root_resource_id
  path_part   = "results"
}

# GET /results method (list recent)
resource "aws_api_gateway_method" "results_list" {
  rest_api_id   = aws_api_gateway_rest_api.image_analysis_api.id
  resource_id   = aws_api_gateway_resource.results.id
  http_method   = "GET"
  authorization = "NONE"
}

# GET /results integration
resource "aws_api_gateway_integration" "results_list_integration" {
  rest_api_id             = aws_api_gateway_rest_api.image_analysis_api.id
  resource_id             = aws_api_gateway_resource.results.id
  http_method             = aws_api_gateway_method.results_list.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_get_results.invoke_arn
}

# /results/{imageId} resource
resource "aws_api_gateway_resource" "results_image" {
  rest_api_id = aws_api_gateway_rest_api.image_analysis_api.id
  parent_id   = aws_api_gateway_resource.results.id
  path_part   = "{imageId}"
}

# GET /results/{imageId} method
resource "aws_api_gateway_method" "results_get" {
  rest_api_id   = aws_api_gateway_rest_api.image_analysis_api.id
  resource_id   = aws_api_gateway_resource.results_image.id
  http_method   = "GET"
  authorization = "NONE"
}

# GET /results/{imageId} integration
resource "aws_api_gateway_integration" "results_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.image_analysis_api.id
  resource_id             = aws_api_gateway_resource.results_image.id
  http_method             = aws_api_gateway_method.results_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_get_results.invoke_arn
}

# CORS for /upload-url
module "cors_upload_url" {
  source          = "squidfunk/api-gateway-enable-cors/aws"
  version         = "0.3.3"
  api_id          = aws_api_gateway_rest_api.image_analysis_api.id
  api_resource_id = aws_api_gateway_resource.upload_url.id
}

# CORS for /results
module "cors_results" {
  source          = "squidfunk/api-gateway-enable-cors/aws"
  version         = "0.3.3"
  api_id          = aws_api_gateway_rest_api.image_analysis_api.id
  api_resource_id = aws_api_gateway_resource.results.id
}

# CORS for /results/{imageId}
module "cors_results_image" {
  source          = "squidfunk/api-gateway-enable-cors/aws"
  version         = "0.3.3"
  api_id          = aws_api_gateway_rest_api.image_analysis_api.id
  api_resource_id = aws_api_gateway_resource.results_image.id
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.image_analysis_api.id

  depends_on = [
    aws_api_gateway_integration.upload_url_integration,
    aws_api_gateway_integration.results_list_integration,
    aws_api_gateway_integration.results_get_integration,
    module.cors_upload_url,
    module.cors_results,
    module.cors_results_image
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.image_analysis_api.id
  stage_name    = "prod"

  tags = {
    Name        = "image-analysis-api-prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "api_upload_url_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_upload_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_analysis_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_get_results_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_get_results.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_analysis_api.execution_arn}/*/*"
}

# S3 Outputs
output "bucket_name" {
  value       = aws_s3_bucket.trigger_bucket.id
  description = "Name of the S3 bucket for image uploads"
}

output "bucket_arn" {
  value       = aws_s3_bucket.trigger_bucket.arn
  description = "ARN of the S3 bucket"
}

# Lambda Function Outputs
output "orchestrator_function_name" {
  value       = aws_lambda_function.orchestrator.function_name
  description = "Name of the orchestrator Lambda function"
}

output "object_detector_function_name" {
  value       = aws_lambda_function.object_detector.function_name
  description = "Name of the object detector Lambda function"
}

output "face_detector_function_name" {
  value       = aws_lambda_function.face_detector.function_name
  description = "Name of the face detector Lambda function"
}

output "content_moderator_function_name" {
  value       = aws_lambda_function.content_moderator.function_name
  description = "Name of the content moderator Lambda function"
}

output "results_aggregator_function_name" {
  value       = aws_lambda_function.results_aggregator.function_name
  description = "Name of the results aggregator Lambda function"
}

# DynamoDB Output
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.image_analysis_results.name
  description = "Name of the DynamoDB table storing analysis results"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.image_analysis_results.arn
  description = "ARN of the DynamoDB table"
}

# Step Functions Output
output "step_functions_arn" {
  value       = aws_sfn_state_machine.image_analysis.arn
  description = "ARN of the Step Functions state machine"
}

output "step_functions_name" {
  value       = aws_sfn_state_machine.image_analysis.name
  description = "Name of the Step Functions state machine"
}

# EventBridge Output
output "eventbridge_rule_name" {
  value       = aws_cloudwatch_event_rule.s3_object_created.name
  description = "Name of the EventBridge rule"
}

output "eventbridge_rule_arn" {
  value       = aws_cloudwatch_event_rule.s3_object_created.arn
  description = "ARN of the EventBridge rule"
}

# API Gateway Outputs
output "api_gateway_url" {
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}"
  description = "Base URL for the API Gateway (use this in frontend VITE_API_BASE_URL)"
}

output "api_gateway_id" {
  value       = aws_api_gateway_rest_api.image_analysis_api.id
  description = "ID of the API Gateway REST API"
}

# Frontend Hosting Outputs
output "frontend_bucket_name" {
  value       = aws_s3_bucket.frontend_bucket.id
  description = "Name of the S3 bucket hosting the frontend"
}

# CloudFront outputs commented out until account is verified
# output "cloudfront_distribution_id" {
#   value       = aws_cloudfront_distribution.frontend_distribution.id
#   description = "ID of the CloudFront distribution"
# }
#
# output "cloudfront_domain_name" {
#   value       = aws_cloudfront_distribution.frontend_distribution.domain_name
#   description = "Domain name of the CloudFront distribution (use this to access your frontend)"
# }
#
# output "cloudfront_url" {
#   value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
#   description = "Full HTTPS URL of your frontend application"
# }

# S3 website URL (temporary until CloudFront is available)
output "frontend_website_url" {
  value       = "http://${aws_s3_bucket.frontend_bucket.id}.s3-website-${var.aws_region}.amazonaws.com"
  description = "S3 website URL to access your frontend application"
}

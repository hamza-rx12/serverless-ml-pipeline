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

output "results_aggregator_function_name" {
  value       = aws_lambda_function.results_aggregator.function_name
  description = "Name of the results aggregator Lambda function"
}

output "text_detector_function_name" {
  value       = aws_lambda_function.text_detector.function_name
  description = "Name of the text detector Lambda function"
}

# Service-Specific DynamoDB Tables
output "text_detection_table_name" {
  value       = aws_dynamodb_table.text_detection_results.name
  description = "Name of the text detection DynamoDB table"
}

output "face_detection_table_name" {
  value       = aws_dynamodb_table.face_detection_results.name
  description = "Name of the face detection DynamoDB table"
}

output "object_detection_table_name" {
  value       = aws_dynamodb_table.object_detection_results.name
  description = "Name of the object detection DynamoDB table"
}

# Service-Specific Step Functions
output "text_detection_workflow_arn" {
  value       = aws_sfn_state_machine.text_detection.arn
  description = "ARN of the text detection Step Functions workflow"
}

output "face_detection_workflow_arn" {
  value       = aws_sfn_state_machine.face_detection.arn
  description = "ARN of the face detection Step Functions workflow"
}

output "object_detection_workflow_arn" {
  value       = aws_sfn_state_machine.object_detection.arn
  description = "ARN of the object detection Step Functions workflow"
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

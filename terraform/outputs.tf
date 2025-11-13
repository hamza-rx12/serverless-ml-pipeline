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

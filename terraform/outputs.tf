# Outputs
output "bucket_name" {
  value       = aws_s3_bucket.trigger_bucket.id
  description = "Name of the S3 bucket that triggers Lambda"
}

output "lambda_function_name" {
  value       = aws_lambda_function.s3_processor.function_name
  description = "Name of the Lambda function"
}

# Lambda function for generating presigned URLs
data "archive_file" "api_upload_url_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/api-upload-url"
  output_path = "${path.module}/api-upload-url.zip"
}

resource "aws_lambda_function" "api_upload_url" {
  filename         = data.archive_file.api_upload_url_zip.output_path
  function_name    = "api-upload-url"
  role             = aws_iam_role.api_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.api_upload_url_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.trigger_bucket.id
    }
  }

  tags = {
    Name        = "api-upload-url"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda function for getting analysis results
data "archive_file" "api_get_results_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/api-get-results"
  output_path = "${path.module}/api-get-results.zip"
}

resource "aws_lambda_function" "api_get_results" {
  filename         = data.archive_file.api_get_results_zip.output_path
  function_name    = "api-get-results"
  role             = aws_iam_role.api_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.api_get_results_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.image_analysis_results.name
    }
  }

  tags = {
    Name        = "api-get-results"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_upload_url_logs" {
  name              = "/aws/lambda/api-upload-url"
  retention_in_days = 7

  tags = {
    Name        = "api-upload-url-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "api_get_results_logs" {
  name              = "/aws/lambda/api-get-results"
  retention_in_days = 7

  tags = {
    Name        = "api-get-results-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

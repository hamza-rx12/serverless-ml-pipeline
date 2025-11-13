# Orchestrator Lambda
data "archive_file" "orchestrator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/orchestrator/"
  output_path = "${path.module}/orchestrator.zip"
}

resource "aws_lambda_function" "orchestrator" {
  filename         = data.archive_file.orchestrator_zip.output_path
  function_name    = "image-analysis-orchestrator"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.orchestrator_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  tags = {
    Name        = "orchestrator"
    Environment = var.environment
  }
}

# Object Detector Lambda
data "archive_file" "object_detector_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/object-detector/"
  output_path = "${path.module}/object-detector.zip"
}

resource "aws_lambda_function" "object_detector" {
  filename         = data.archive_file.object_detector_zip.output_path
  function_name    = "image-analysis-object-detector"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.object_detector_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  tags = {
    Name        = "object-detector"
    Environment = var.environment
  }
}

# Face Detector Lambda
data "archive_file" "face_detector_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/face-detector/"
  output_path = "${path.module}/face-detector.zip"
}

resource "aws_lambda_function" "face_detector" {
  filename         = data.archive_file.face_detector_zip.output_path
  function_name    = "image-analysis-face-detector"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.face_detector_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  tags = {
    Name        = "face-detector"
    Environment = var.environment
  }
}

# Content Moderator Lambda
data "archive_file" "content_moderator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/content-moderator/"
  output_path = "${path.module}/content-moderator.zip"
}

resource "aws_lambda_function" "content_moderator" {
  filename         = data.archive_file.content_moderator_zip.output_path
  function_name    = "image-analysis-content-moderator"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.content_moderator_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  tags = {
    Name        = "content-moderator"
    Environment = var.environment
  }
}

# Results Aggregator Lambda
data "archive_file" "results_aggregator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/results-aggregator/"
  output_path = "${path.module}/results-aggregator.zip"
}

resource "aws_lambda_function" "results_aggregator" {
  filename         = data.archive_file.results_aggregator_zip.output_path
  function_name    = "image-analysis-results-aggregator"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.results_aggregator_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.image_analysis_results.name
    }
  }

  tags = {
    Name        = "results-aggregator"
    Environment = var.environment
  }
}

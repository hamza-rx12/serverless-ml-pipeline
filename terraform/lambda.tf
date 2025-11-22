# Orchestrator Lambda
data "archive_file" "orchestrator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/orchestrator/"
  output_path = "${path.module}/../build/orchestrator.zip"
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
  output_path = "${path.module}/../build/object-detector.zip"
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
  output_path = "${path.module}/../build/face-detector.zip"
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

# Results Aggregator Lambda
data "archive_file" "results_aggregator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/results-aggregator/"
  output_path = "${path.module}/../build/results-aggregator.zip"
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
      TEXT_DETECTION_TABLE   = aws_dynamodb_table.text_detection_results.name
      FACE_DETECTION_TABLE   = aws_dynamodb_table.face_detection_results.name
      OBJECT_DETECTION_TABLE = aws_dynamodb_table.object_detection_results.name
    }
  }

  tags = {
    Name        = "results-aggregator"
    Environment = var.environment
  }
}

# Text Detector Lambda
data "archive_file" "text_detector_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/text-detector/"
  output_path = "${path.module}/../build/text-detector.zip"
}

resource "aws_lambda_function" "text_detector" {
  filename         = data.archive_file.text_detector_zip.output_path
  function_name    = "image-analysis-text-detector"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.text_detector_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  tags = {
    Name        = "text-detector"
    Environment = var.environment
  }
}

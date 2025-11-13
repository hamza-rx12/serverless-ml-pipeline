# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "image-analysis-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach basic execution policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 Read Access Policy
resource "aws_iam_policy" "lambda_s3_read" {
  name        = "lambda-s3-read-policy"
  description = "Allow Lambda to read from S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.trigger_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_read.arn
}

# Rekognition Access Policy
resource "aws_iam_policy" "lambda_rekognition" {
  name        = "lambda-rekognition-policy"
  description = "Allow Lambda to use Rekognition APIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectFaces",
          "rekognition:DetectModerationLabels"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_rekognition" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_rekognition.arn
}

# DynamoDB Write Access Policy
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "lambda-dynamodb-policy"
  description = "Allow Lambda to write to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.image_analysis_results.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

# Step Functions Execution Role
resource "aws_iam_role" "step_functions_role" {
  name = "image-analysis-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

# Step Functions Lambda Invoke Policy
resource "aws_iam_policy" "step_functions_lambda" {
  name        = "step-functions-lambda-invoke-policy"
  description = "Allow Step Functions to invoke Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.orchestrator.arn,
          aws_lambda_function.object_detector.arn,
          aws_lambda_function.face_detector.arn,
          aws_lambda_function.content_moderator.arn,
          aws_lambda_function.results_aggregator.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_lambda" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_lambda.arn
}

# EventBridge Role
resource "aws_iam_role" "eventbridge_role" {
  name = "image-analysis-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

# EventBridge Step Functions Policy
resource "aws_iam_policy" "eventbridge_step_functions" {
  name        = "eventbridge-step-functions-policy"
  description = "Allow EventBridge to start Step Functions execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.image_analysis.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_step_functions" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_step_functions.arn
}

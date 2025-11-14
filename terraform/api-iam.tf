# IAM role for API Lambda functions
resource "aws_iam_role" "api_lambda_role" {
  name = "api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "api-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Logs policy for API Lambda functions
resource "aws_iam_role_policy" "api_lambda_cloudwatch_policy" {
  name = "api-lambda-cloudwatch-policy"
  role = aws_iam_role.api_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# S3 policy for API Lambda (presigned URL generation and read access)
resource "aws_iam_role_policy" "api_lambda_s3_policy" {
  name = "api-lambda-s3-policy"
  role = aws_iam_role.api_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.trigger_bucket.arn,
          "${aws_s3_bucket.trigger_bucket.arn}/*"
        ]
      }
    ]
  })
}

# DynamoDB policy for API Lambda (read access)
resource "aws_iam_role_policy" "api_lambda_dynamodb_policy" {
  name = "api-lambda-dynamodb-policy"
  role = aws_iam_role.api_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.image_analysis_results.arn,
          "${aws_dynamodb_table.image_analysis_results.arn}/*"
        ]
      }
    ]
  })
}

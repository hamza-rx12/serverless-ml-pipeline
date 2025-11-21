# Thumbnail Generator Lambda Function

# Package Lambda function with dependencies
data "archive_file" "thumbnail_generator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/thumbnail-generator"
  output_path = "${path.module}/../lambdas/thumbnail-generator.zip"
  excludes    = ["__pycache__", "*.pyc"]
}

# Lambda function
resource "aws_lambda_function" "thumbnail_generator" {
  filename         = data.archive_file.thumbnail_generator_zip.output_path
  function_name    = "image-analysis-thumbnail-generator"
  role            = aws_iam_role.thumbnail_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.thumbnail_generator_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.trigger_bucket.id
    }
  }

  # Pillow requires more ephemeral storage for image processing
  ephemeral_storage {
    size = 1024 # 1GB
  }

  tags = {
    Name        = "thumbnail-generator"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for Thumbnail Generator Lambda
resource "aws_iam_role" "thumbnail_lambda_role" {
  name = "thumbnail-generator-lambda-role"

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
    Name        = "thumbnail-generator-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "thumbnail_lambda_basic" {
  role       = aws_iam_role.thumbnail_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 permissions for thumbnail generator
resource "aws_iam_role_policy" "thumbnail_s3_policy" {
  name = "thumbnail-generator-s3-policy"
  role = aws_iam_role.thumbnail_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.trigger_bucket.arn}/*"
      }
    ]
  })
}

# EventBridge rule to trigger thumbnail generation
resource "aws_cloudwatch_event_rule" "thumbnail_generator_rule" {
  name        = "thumbnail-generator-s3-upload"
  description = "Trigger thumbnail generation on image upload"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.trigger_bucket.id]
      }
      object = {
        key = [{
          # Don't generate thumbnails for thumbnails
          anything-but = {
            prefix = "thumbnails/"
          }
        }]
      }
    }
  })

  tags = {
    Name        = "thumbnail-generator-rule"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EventBridge target for thumbnail generator
resource "aws_cloudwatch_event_target" "thumbnail_generator_target" {
  rule      = aws_cloudwatch_event_rule.thumbnail_generator_rule.name
  target_id = "ThumbnailGeneratorLambda"
  arn       = aws_lambda_function.thumbnail_generator.arn
}

# Lambda permission for EventBridge to invoke thumbnail generator
resource "aws_lambda_permission" "allow_eventbridge_thumbnail" {
  statement_id  = "AllowEventBridgeInvokeThumbnailGenerator"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnail_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.thumbnail_generator_rule.arn
}

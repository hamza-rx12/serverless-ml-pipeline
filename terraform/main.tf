provider "aws" {
    region = "us-east-1"
    profile = "default"
}

# resource "random_id" "bucket_suffix" {
#   byte_length = 4
# }
# resource "aws_s3_bucket" "test" {
#     bucket = "terraform-bucket-${random_id.bucket_suffix.hex}"
# }

# 1. Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "s3_trigger_lambda_role"
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


resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
   
# Create zip file automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/../lambdas/image-analyzer/" 
  output_path = "image-analyzer.zip"
}

# 2. Lambda Function
resource "aws_lambda_function" "s3_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "s3-event-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.handler"
  runtime         = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}


# 3. S3 Bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "trigger_bucket" {
  bucket = "lambda-trigger-bucket-${random_id.bucket_suffix.hex}"
}


# 4. Lambda Permission (S3 can invoke Lambda)
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.trigger_bucket.arn
}


# 5. S3 Event Notification
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.trigger_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}


# Outputs
output "bucket_name" {
  value = aws_s3_bucket.trigger_bucket.id
}

output "lambda_function_name" {
  value = aws_lambda_function.s3_processor.function_name
}

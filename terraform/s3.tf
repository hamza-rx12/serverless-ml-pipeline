# Generate random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for image uploads
resource "aws_s3_bucket" "trigger_bucket" {
  bucket        = "image-analysis-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true # For testing purposes only

  tags = {
    Name        = "image-analysis-bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Enable EventBridge notifications for S3 bucket
resource "aws_s3_bucket_notification" "eventbridge" {
  bucket      = aws_s3_bucket.trigger_bucket.id
  eventbridge = true
}

# CORS configuration for direct uploads from browser
resource "aws_s3_bucket_cors_configuration" "trigger_bucket_cors" {
  bucket = aws_s3_bucket.trigger_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] # In production, restrict to your domain
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

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

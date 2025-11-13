# DynamoDB table for storing image analysis results
resource "aws_dynamodb_table" "image_analysis_results" {
  name         = "image-analysis-results"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "image_id"
  range_key    = "timestamp"

  attribute {
    name = "image_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # Enable point-in-time recovery for production
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "image-analysis-results"
    Environment = var.environment
    Project     = var.project_name
  }
}

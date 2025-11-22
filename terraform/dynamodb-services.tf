# Service-Specific DynamoDB Tables

# Text Detection Results Table
resource "aws_dynamodb_table" "text_detection_results" {
  name           = "text-detection-results"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "image_id"
  range_key      = "timestamp"

  attribute {
    name = "image_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "text-detection-results"
    Service     = "text-detection"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Face Detection Results Table
resource "aws_dynamodb_table" "face_detection_results" {
  name           = "face-detection-results"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "image_id"
  range_key      = "timestamp"

  attribute {
    name = "image_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "face-detection-results"
    Service     = "face-detection"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Object Detection Results Table
resource "aws_dynamodb_table" "object_detection_results" {
  name           = "object-detection-results"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "image_id"
  range_key      = "timestamp"

  attribute {
    name = "image_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "object-detection-results"
    Service     = "object-detection"
    Environment = var.environment
    Project     = var.project_name
  }
}

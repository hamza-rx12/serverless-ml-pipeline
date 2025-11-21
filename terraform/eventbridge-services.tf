# Service-Specific EventBridge Rules

# Text Detection Service Rule
resource "aws_cloudwatch_event_rule" "text_detection_upload" {
  name        = "text-detection-s3-upload"
  description = "Trigger text detection workflow when image is uploaded to text-detection/ prefix"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.trigger_bucket.id]
      }
      object = {
        key = [{
          prefix = "text-detection/"
        }]
      }
    }
  })

  tags = {
    Name        = "text-detection-s3-upload"
    Service     = "text-detection"
    Environment = var.environment
  }
}

# Face Detection Service Rule
resource "aws_cloudwatch_event_rule" "face_detection_upload" {
  name        = "face-detection-s3-upload"
  description = "Trigger face detection workflow when image is uploaded to face-detection/ prefix"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.trigger_bucket.id]
      }
      object = {
        key = [{
          prefix = "face-detection/"
        }]
      }
    }
  })

  tags = {
    Name        = "face-detection-s3-upload"
    Service     = "face-detection"
    Environment = var.environment
  }
}

# Object Detection Service Rule
resource "aws_cloudwatch_event_rule" "object_detection_upload" {
  name        = "object-detection-s3-upload"
  description = "Trigger object detection workflow when image is uploaded to object-detection/ prefix"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.trigger_bucket.id]
      }
      object = {
        key = [{
          prefix = "object-detection/"
        }]
      }
    }
  })

  tags = {
    Name        = "object-detection-s3-upload"
    Service     = "object-detection"
    Environment = var.environment
  }
}

# EventBridge Targets - will be added after Step Functions are created
# (Targets are defined in step-functions-services.tf)

# EventBridge Rule to trigger Step Functions on S3 upload
resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "image-analysis-s3-upload"
  description = "Trigger image analysis workflow when image is uploaded to S3"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.trigger_bucket.id]
      }
      object = {
        key = [
          {
            suffix = ".jpg"
          },
          {
            suffix = ".jpeg"
          },
          {
            suffix = ".png"
          },
          {
            suffix = ".gif"
          },
          {
            suffix = ".bmp"
          },
          {
            suffix = ".webp"
          }
        ]
      }
    }
  })

  tags = {
    Name        = "image-analysis-s3-upload"
    Environment = var.environment
  }
}

# EventBridge Target - Step Functions State Machine
resource "aws_cloudwatch_event_target" "step_functions" {
  rule     = aws_cloudwatch_event_rule.s3_object_created.name
  arn      = aws_sfn_state_machine.image_analysis.arn
  role_arn = aws_iam_role.eventbridge_role.arn

  # Transform the S3 event to the format expected by Step Functions
  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name"
      key    = "$.detail.object.key"
      time   = "$.time"
    }

    input_template = <<EOF
{
  "bucket": <bucket>,
  "key": <key>,
  "upload_time": <time>
}
EOF
  }
}

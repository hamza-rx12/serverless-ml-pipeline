# Service-Specific Step Functions

# Text Detection Workflow
resource "aws_sfn_state_machine" "text_detection" {
  name     = "text-detection-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Text Detection Workflow - OCR analysis using Rekognition"
    StartAt = "ValidateImage"
    States = {
      ValidateImage = {
        Type       = "Task"
        Resource   = aws_lambda_function.orchestrator.arn
        ResultPath = "$.orchestrator_result"
        Next       = "CheckValidation"
      }

      CheckValidation = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.orchestrator_result.valid"
          BooleanEquals = true
          Next          = "DetectText"
        }]
        Default = "Failed"
      }

      DetectText = {
        Type       = "Task"
        Resource   = aws_lambda_function.text_detector.arn
        ResultPath = "$.text_results"
        Next       = "StoreResults"
      }

      StoreResults = {
        Type     = "Task"
        Resource = aws_lambda_function.results_aggregator.arn
        End      = true
      }

      Failed = {
        Type  = "Fail"
        Cause = "Image validation failed"
      }
    }
  })

  tags = {
    Name        = "text-detection-workflow"
    Service     = "text-detection"
    Environment = var.environment
  }
}

# Face Detection Workflow
resource "aws_sfn_state_machine" "face_detection" {
  name     = "face-detection-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Face Detection Workflow - Face analysis using Rekognition"
    StartAt = "ValidateImage"
    States = {
      ValidateImage = {
        Type       = "Task"
        Resource   = aws_lambda_function.orchestrator.arn
        ResultPath = "$.orchestrator_result"
        Next       = "CheckValidation"
      }

      CheckValidation = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.orchestrator_result.valid"
          BooleanEquals = true
          Next          = "DetectFaces"
        }]
        Default = "Failed"
      }

      DetectFaces = {
        Type       = "Task"
        Resource   = aws_lambda_function.face_detector.arn
        ResultPath = "$.face_results"
        Next       = "StoreResults"
      }

      StoreResults = {
        Type     = "Task"
        Resource = aws_lambda_function.results_aggregator.arn
        End      = true
      }

      Failed = {
        Type  = "Fail"
        Cause = "Image validation failed"
      }
    }
  })

  tags = {
    Name        = "face-detection-workflow"
    Service     = "face-detection"
    Environment = var.environment
  }
}

# Object Detection Workflow
resource "aws_sfn_state_machine" "object_detection" {
  name     = "object-detection-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Object Detection Workflow - Object/label detection using Rekognition"
    StartAt = "ValidateImage"
    States = {
      ValidateImage = {
        Type       = "Task"
        Resource   = aws_lambda_function.orchestrator.arn
        ResultPath = "$.orchestrator_result"
        Next       = "CheckValidation"
      }

      CheckValidation = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.orchestrator_result.valid"
          BooleanEquals = true
          Next          = "DetectObjects"
        }]
        Default = "Failed"
      }

      DetectObjects = {
        Type       = "Task"
        Resource   = aws_lambda_function.object_detector.arn
        ResultPath = "$.object_results"
        Next       = "StoreResults"
      }

      StoreResults = {
        Type     = "Task"
        Resource = aws_lambda_function.results_aggregator.arn
        End      = true
      }

      Failed = {
        Type  = "Fail"
        Cause = "Image validation failed"
      }
    }
  })

  tags = {
    Name        = "object-detection-workflow"
    Service     = "object-detection"
    Environment = var.environment
  }
}

# EventBridge Targets
resource "aws_cloudwatch_event_target" "text_detection" {
  rule     = aws_cloudwatch_event_rule.text_detection_upload.name
  arn      = aws_sfn_state_machine.text_detection.arn
  role_arn = aws_iam_role.eventbridge_role.arn

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

resource "aws_cloudwatch_event_target" "face_detection" {
  rule     = aws_cloudwatch_event_rule.face_detection_upload.name
  arn      = aws_sfn_state_machine.face_detection.arn
  role_arn = aws_iam_role.eventbridge_role.arn

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

resource "aws_cloudwatch_event_target" "object_detection" {
  rule     = aws_cloudwatch_event_rule.object_detection_upload.name
  arn      = aws_sfn_state_machine.object_detection.arn
  role_arn = aws_iam_role.eventbridge_role.arn

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

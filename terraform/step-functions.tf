# Step Functions State Machine for Image Analysis
resource "aws_sfn_state_machine" "image_analysis" {
  name     = "image-analysis-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Image Analysis Workflow - Orchestrates Rekognition analysis through multiple Lambda functions"
    StartAt = "ValidateImage"
    States = {
      ValidateImage = {
        Type       = "Task"
        Resource   = aws_lambda_function.orchestrator.arn
        Comment    = "Validate image format and extract metadata"
        ResultPath = "$.orchestrator_result"
        Next       = "CheckValidation"
        Retry = [
          {
            ErrorEquals = [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ValidationFailed"
          }
        ]
      }

      CheckValidation = {
        Type    = "Choice"
        Comment = "Check if image validation passed"
        Choices = [
          {
            Variable      = "$.orchestrator_result.valid"
            BooleanEquals = true
            Next          = "ParallelDetection"
          }
        ]
        Default = "ValidationFailed"
      }

      ParallelDetection = {
        Type       = "Parallel"
        Comment    = "Run all detection Lambda functions in parallel"
        ResultPath = "$.detection_results"
        Next       = "AggregateResults"
        Branches = [
          {
            StartAt = "DetectObjects"
            States = {
              DetectObjects = {
                Type       = "Task"
                Resource   = aws_lambda_function.object_detector.arn
                Comment    = "Detect objects and labels using Rekognition"
                InputPath  = "$.orchestrator_result"
                ResultPath = "$.objects"
                End        = true
                Retry = [
                  {
                    ErrorEquals = [
                      "Lambda.ServiceException",
                      "Lambda.AWSLambdaException",
                      "Lambda.SdkClientException"
                    ]
                    IntervalSeconds = 2
                    MaxAttempts     = 3
                    BackoffRate     = 2.0
                  }
                ]
                Catch = [
                  {
                    ErrorEquals = ["States.ALL"]
                    ResultPath  = "$.error"
                    Next        = "ObjectDetectionFailed"
                  }
                ]
              }
              ObjectDetectionFailed = {
                Type    = "Pass"
                Comment = "Object detection failed, return empty result"
                Result = {
                  statusCode     = 500
                  detection_type = "objects"
                  error          = "Detection failed"
                  objects        = []
                  count          = 0
                }
                ResultPath = "$.objects"
                End        = true
              }
            }
          },
          {
            StartAt = "DetectFaces"
            States = {
              DetectFaces = {
                Type       = "Task"
                Resource   = aws_lambda_function.face_detector.arn
                Comment    = "Detect faces and attributes using Rekognition"
                InputPath  = "$.orchestrator_result"
                ResultPath = "$.faces"
                End        = true
                Retry = [
                  {
                    ErrorEquals = [
                      "Lambda.ServiceException",
                      "Lambda.AWSLambdaException",
                      "Lambda.SdkClientException"
                    ]
                    IntervalSeconds = 2
                    MaxAttempts     = 3
                    BackoffRate     = 2.0
                  }
                ]
                Catch = [
                  {
                    ErrorEquals = ["States.ALL"]
                    ResultPath  = "$.error"
                    Next        = "FaceDetectionFailed"
                  }
                ]
              }
              FaceDetectionFailed = {
                Type    = "Pass"
                Comment = "Face detection failed, return empty result"
                Result = {
                  statusCode     = 500
                  detection_type = "faces"
                  error          = "Detection failed"
                  faces          = []
                  count          = 0
                }
                ResultPath = "$.faces"
                End        = true
              }
            }
          },
          {
            StartAt = "ModerateContent"
            States = {
              ModerateContent = {
                Type       = "Task"
                Resource   = aws_lambda_function.content_moderator.arn
                Comment    = "Detect inappropriate content using Rekognition"
                InputPath  = "$.orchestrator_result"
                ResultPath = "$.moderation"
                End        = true
                Retry = [
                  {
                    ErrorEquals = [
                      "Lambda.ServiceException",
                      "Lambda.AWSLambdaException",
                      "Lambda.SdkClientException"
                    ]
                    IntervalSeconds = 2
                    MaxAttempts     = 3
                    BackoffRate     = 2.0
                  }
                ]
                Catch = [
                  {
                    ErrorEquals = ["States.ALL"]
                    ResultPath  = "$.error"
                    Next        = "ModerationFailed"
                  }
                ]
              }
              ModerationFailed = {
                Type    = "Pass"
                Comment = "Content moderation failed, return safe default"
                Result = {
                  statusCode        = 500
                  detection_type    = "moderation"
                  error             = "Moderation failed"
                  is_safe           = true
                  moderation_labels = []
                  flags_count       = 0
                }
                ResultPath = "$.moderation"
                End        = true
              }
            }
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "DetectionFailed"
          }
        ]
      }

      AggregateResults = {
        Type     = "Task"
        Resource = aws_lambda_function.results_aggregator.arn
        Comment  = "Aggregate all results and store in DynamoDB"
        End      = true
        Retry = [
          {
            ErrorEquals = [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "AggregationFailed"
          }
        ]
      }

      ValidationFailed = {
        Type    = "Fail"
        Comment = "Image validation failed"
        Error   = "ValidationError"
        Cause   = "Image format not supported or validation failed"
      }

      DetectionFailed = {
        Type    = "Fail"
        Comment = "Detection process failed"
        Error   = "DetectionError"
        Cause   = "One or more detection processes failed"
      }

      AggregationFailed = {
        Type    = "Fail"
        Comment = "Results aggregation failed"
        Error   = "AggregationError"
        Cause   = "Failed to aggregate and store results"
      }
    }
  })

  tags = {
    Name        = "image-analysis-workflow"
    Environment = var.environment
    Project     = var.project_name
  }
}

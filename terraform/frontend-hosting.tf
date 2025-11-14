# S3 bucket for frontend hosting
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "image-analysis-frontend-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "image-analysis-frontend"
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3 bucket public access block configuration
# Allow public access for website hosting (until CloudFront is available)
resource "aws_s3_bucket_public_access_block" "frontend_bucket_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket policy for public website access
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend_bucket_public_access]
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # SPA fallback
  }
}

# CloudFront resources commented out until account is verified
# Uncomment these after AWS account verification

# # CloudFront Origin Access Control
# resource "aws_cloudfront_origin_access_control" "frontend_oac" {
#   name                              = "frontend-oac-${random_id.bucket_suffix.hex}"
#   description                       = "OAC for frontend S3 bucket"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

# # CloudFront distribution
# resource "aws_cloudfront_distribution" "frontend_distribution" {
#   enabled             = true
#   is_ipv6_enabled     = true
#   default_root_object = "index.html"
#   price_class         = "PriceClass_100" # Use only North America and Europe
#   comment             = "CloudFront distribution for image analysis frontend"
#
#   origin {
#     domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
#     origin_id                = "S3-${aws_s3_bucket.frontend_bucket.id}"
#     origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
#   }
#
#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "S3-${aws_s3_bucket.frontend_bucket.id}"
#
#     forwarded_values {
#       query_string = false
#
#       cookies {
#         forward = "none"
#       }
#     }
#
#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     compress               = true
#   }
#
#   # Custom error response for SPA routing
#   custom_error_response {
#     error_code         = 404
#     response_code      = 200
#     response_page_path = "/index.html"
#   }
#
#   custom_error_response {
#     error_code         = 403
#     response_code      = 200
#     response_page_path = "/index.html"
#   }
#
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
#
#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
#
#   tags = {
#     Name        = "image-analysis-frontend-distribution"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

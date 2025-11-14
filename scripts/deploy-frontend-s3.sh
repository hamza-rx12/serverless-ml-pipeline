#!/bin/bash

# Deploy frontend to S3 website hosting (no CloudFront)
# Usage: ./scripts/deploy-frontend-s3.sh

set -e

echo "=== Deploying Frontend to S3 ==="

# Change to project root directory
cd "$(dirname "$0")/.."

# Get Terraform outputs
cd terraform
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
API_URL=$(terraform output -raw api_gateway_url)
cd ..

echo "Frontend Bucket: $FRONTEND_BUCKET"
echo "API Gateway URL: $API_URL"

# Create .env file for frontend
echo "Creating .env file with API URL..."
echo "VITE_API_BASE_URL=$API_URL" > frontend/.env

# Build frontend
echo "Building frontend..."
cd frontend
npm run build
cd ..

# Upload to S3
echo "Uploading to S3..."
aws s3 sync frontend/dist/ s3://$FRONTEND_BUCKET/ --delete

# Make the bucket public for website hosting
echo "Configuring S3 bucket for public website access..."
aws s3api put-bucket-policy --bucket $FRONTEND_BUCKET --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"PublicReadGetObject\",
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::$FRONTEND_BUCKET/*\"
    }
  ]
}"

# Update public access block to allow public website
aws s3api put-public-access-block --bucket $FRONTEND_BUCKET --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Enable S3 website hosting
aws s3 website s3://$FRONTEND_BUCKET/ --index-document index.html --error-document index.html

# Get the website URL
REGION=$(aws configure get region || echo "us-east-1")
WEBSITE_URL="http://$FRONTEND_BUCKET.s3-website-$REGION.amazonaws.com"

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Your application is now available at:"
echo "$WEBSITE_URL"
echo ""
echo "API Gateway URL: $API_URL"
echo ""

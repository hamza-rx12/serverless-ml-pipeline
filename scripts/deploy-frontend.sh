#!/bin/bash

# Deploy frontend to S3 and invalidate CloudFront cache
# Usage: ./scripts/deploy-frontend.sh

set -e

echo "=== Deploying Frontend to AWS ==="

# Get Terraform outputs
cd terraform
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)
API_URL=$(terraform output -raw api_gateway_url)
cd ..

echo "Frontend Bucket: $FRONTEND_BUCKET"
echo "CloudFront Distribution: $CLOUDFRONT_ID"
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

# Invalidate CloudFront cache
echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Your application is now available at:"
terraform -chdir=terraform output -raw cloudfront_url
echo ""

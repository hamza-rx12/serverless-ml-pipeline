# AWS Image Analysis Platform

A production-ready serverless image analysis platform built on AWS that automatically analyzes uploaded images using AI services. The system performs object detection, face analysis, and content moderation using AWS Rekognition, with a modern React frontend for image uploads and results visualization.

## Features

- **Automated Image Analysis** - Upload images and get instant AI-powered analysis
- **Object Detection** - Identifies objects, labels, and categories in images
- **Face Detection** - Detects faces and analyzes attributes (age, gender, emotions)
- **Content Moderation** - Flags inappropriate or unsafe content
- **Real-time Results** - Live updates as analysis completes
- **Modern UI** - React + Vite frontend with responsive design
- **Serverless Architecture** - Auto-scaling, pay-per-use infrastructure
- **Infrastructure as Code** - Fully managed with Terraform

## Architecture

### Backend Pipeline
```
S3 Upload → EventBridge → Step Functions → [3 Lambda Functions in Parallel] → DynamoDB
                                           ├─ Object Detector
                                           ├─ Face Detector
                                           └─ Content Moderator
```

### Frontend Stack
```
React (Vite) → API Gateway → Lambda Functions → S3 + DynamoDB
                             ├─ Presigned URL Generator
                             └─ Results Query API
```

### AWS Services Used

- **S3** - Image storage with CORS for direct uploads
- **EventBridge** - Event-driven triggers
- **Step Functions** - Workflow orchestration
- **Lambda** - 7 serverless functions (5 analysis + 2 API)
- **Rekognition** - AI-powered image analysis
- **DynamoDB** - Results storage
- **API Gateway** - REST API for frontend
- **CloudFront** - CDN for frontend hosting
- **IAM** - Security and permissions

## Project Structure

```
aws-project/
├── frontend/                  # React application
│   ├── src/
│   │   ├── components/       # ImageUpload, ResultsDisplay
│   │   ├── services/         # API client
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   └── vite.config.js
│
├── lambdas/                   # Lambda functions
│   ├── orchestrator/         # Image validation
│   ├── object-detector/      # Object detection
│   ├── face-detector/        # Face analysis
│   ├── content-moderator/    # Content moderation
│   ├── results-aggregator/   # Results collection
│   ├── api-upload-url/       # Presigned URL API
│   └── api-get-results/      # Results query API
│
├── terraform/                 # Infrastructure as Code
│   ├── providers.tf          # AWS provider
│   ├── s3.tf                 # S3 buckets + CORS
│   ├── lambda.tf             # Analysis Lambda functions
│   ├── api-lambda.tf         # API Lambda functions
│   ├── api-gateway.tf        # REST API
│   ├── api-iam.tf            # API IAM roles
│   ├── iam.tf                # Analysis IAM roles
│   ├── step-functions.tf     # State machine
│   ├── dynamodb.tf           # Results table
│   ├── eventbridge.tf        # Event routing
│   ├── frontend-hosting.tf   # CloudFront + S3
│   ├── outputs.tf            # Terraform outputs
│   └── variables.tf          # Configuration
│
└── scripts/
    └── deploy-frontend.sh    # Frontend deployment script
```

## Prerequisites

- **AWS Account** with appropriate permissions
- **AWS CLI** configured with credentials (`aws configure`)
- **Terraform** >= 1.0
- **Node.js** >= 18 and npm
- **Python** 3.11 (for Lambda functions)

## Quick Start

### 1. Deploy Backend Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will create:
- S3 bucket for image uploads
- Lambda functions for analysis
- Step Functions workflow
- DynamoDB table
- EventBridge rules
- API Gateway endpoints
- CloudFront distribution
- All necessary IAM roles and policies

**Note the outputs** - you'll need the API Gateway URL and CloudFront URL.

### 2. Build and Deploy Frontend

```bash
# Option A: Use deployment script (recommended)
./scripts/deploy-frontend.sh

# Option B: Manual deployment
cd frontend
npm install

# Create .env file with API URL from terraform output
echo "VITE_API_BASE_URL=<your-api-gateway-url>" > .env

# Build and deploy
npm run build
aws s3 sync dist/ s3://<frontend-bucket-name>/ --delete
aws cloudfront create-invalidation --distribution-id <cloudfront-id> --paths "/*"
```

### 3. Access Your Application

Open the CloudFront URL from terraform outputs:

```bash
terraform -chdir=terraform output cloudfront_url
```

## Usage

1. **Upload an Image**
   - Click "Choose an image file" to select an image
   - Supported formats: JPEG, PNG, GIF, BMP, WEBP (max 10MB)
   - Click "Upload & Analyze"

2. **View Results**
   - Results appear automatically after processing (3-10 seconds)
   - See detected objects with confidence scores
   - View face attributes (age, gender, emotions)
   - Check content safety status

3. **Browse History**
   - Recent uploads appear in the right panel
   - Click any image to view its results
   - Results are stored permanently in DynamoDB

## Development

### Local Frontend Development

```bash
cd frontend
npm install

# Create .env with API Gateway URL
echo "VITE_API_BASE_URL=https://xxx.execute-api.us-east-1.amazonaws.com/prod" > .env

# Start dev server
npm run dev
```

Access at `http://localhost:5173`

### Test Backend Manually

Upload an image to the S3 bucket:

```bash
# Get bucket name
BUCKET=$(terraform -chdir=terraform output -raw bucket_name)

# Upload test image
aws s3 cp test-image.jpg s3://$BUCKET/

# Check Step Functions execution
aws stepfunctions list-executions \
  --state-machine-arn $(terraform -chdir=terraform output -raw step_functions_arn)

# Query results
aws dynamodb scan --table-name image-analysis-results
```

## API Endpoints

### POST /upload-url
Generate presigned URL for S3 upload

**Request:**
```json
{
  "fileName": "photo.jpg",
  "fileType": "image/jpeg"
}
```

**Response:**
```json
{
  "uploadUrl": "https://...",
  "imageId": "20241114-abc123-photo.jpg",
  "expiresIn": 300
}
```

### GET /results/{imageId}
Get analysis results for specific image

**Response:**
```json
{
  "image_id": "photo.jpg",
  "timestamp": "2024-11-14T18:30:45Z",
  "status": "completed",
  "analysis_summary": {
    "objects_detected": 5,
    "faces_detected": 2,
    "is_safe": true
  },
  "detection_results": {
    "objects": [...],
    "faces": [...],
    "moderation": [...]
  }
}
```

### GET /results?limit=N
List recent uploads (default limit: 20)

## Cost Estimation

### Per 1000 Images Analyzed:

- **Lambda** - $0.02 (7 functions × ~1s each)
- **Step Functions** - $0.03 (state transitions)
- **Rekognition** - $1.50 (3 API calls per image)
- **DynamoDB** - $0.25 (writes)
- **S3** - $0.02 (storage + requests)
- **CloudFront** - $0.10 (data transfer)

**Total: ~$2/1000 images** + free tier benefits

## Configuration

Edit `terraform/variables.tf` to customize:

```hcl
variable "aws_region" {
  default = "us-east-1"  # Change region
}

variable "lambda_memory_size" {
  default = 128  # Increase for faster processing
}

variable "lambda_timeout" {
  default = 30  # Max execution time
}
```

## Monitoring

### CloudWatch Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/orchestrator --follow
aws logs tail /aws/lambda/api-upload-url --follow

# View Step Functions executions
aws stepfunctions list-executions \
  --state-machine-arn $(terraform -chdir=terraform output -raw step_functions_arn) \
  --max-results 10
```

### Metrics

- Lambda invocations, duration, errors
- Step Functions execution success/failure rates
- API Gateway request counts, latency
- DynamoDB read/write capacity
- S3 bucket size and request metrics

## Troubleshooting

### Images not processing
- Check EventBridge rule is enabled
- Verify S3 bucket notifications are configured
- Check Step Functions execution history
- Review Lambda CloudWatch logs

### Frontend can't upload
- Verify API Gateway URL in `.env` file
- Check S3 CORS configuration
- Ensure Lambda has S3 permissions
- Check browser console for errors

### Results not appearing
- Wait 5-10 seconds for processing
- Check DynamoDB table for entries
- Verify Lambda has DynamoDB permissions
- Review API Lambda CloudWatch logs

## Cleanup

To destroy all resources:

```bash
# Empty S3 buckets first
aws s3 rm s3://$(terraform -chdir=terraform output -raw bucket_name) --recursive
aws s3 rm s3://$(terraform -chdir=terraform output -raw frontend_bucket_name) --recursive

# Destroy infrastructure
cd terraform
terraform destroy
```

## Security Considerations

### Production Recommendations:

1. **CORS** - Restrict S3 CORS to your domain only
2. **API Gateway** - Add authentication (Cognito, API keys)
3. **CloudFront** - Use custom domain with SSL certificate
4. **IAM** - Review and tighten Lambda permissions
5. **S3** - Enable versioning and lifecycle policies
6. **DynamoDB** - Enable encryption at rest
7. **Rate Limiting** - Add API Gateway throttling

## License

This project is licensed under the MIT License.

## Contributing

Contributions welcome! Please open an issue or PR.

## Support

For issues or questions:
- Open a GitHub issue
- Check AWS documentation
- Review CloudWatch logs

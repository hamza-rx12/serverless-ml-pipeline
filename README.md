# AWS Serverless Image Analysis Platform

A production-ready serverless image analysis platform built on AWS that provides three specialized AI-powered services: **Text Detection (OCR)**, **Face Detection**, and **Object Detection**. The platform features event-driven architecture with service-specific workflows, modern React frontend, and complete infrastructure automation via Terraform.

## Features

- **Three Specialized AI Services** - Text Detection, Face Detection, and Object Detection
- **Service-Specific Processing** - Independent workflows for each analysis type
- **Thumbnail Previews** - Auto-generated 200x200px thumbnails for visual history
- **Real-time Results** - Auto-refreshing analysis display with 3-second polling
- **Direct Browser Uploads** - Presigned S3 URLs for efficient file transfers
- **Modern React UI** - Drag-and-drop uploads with service-specific pages
- **Serverless Architecture** - Auto-scaling, pay-per-use infrastructure
- **Infrastructure as Code** - Fully managed with Terraform
- **Service-Specific History** - Separate result storage and filtering per service

## Architecture

### Service-Specific Architecture

The platform uses **three independent workflows**, one for each AI service:

```
┌─────────────────────────────────────────────────────────┐
│                    User / Browser                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  React Frontend (S3 Static Site + CloudFront)            │
│  • /text-detection    • /face-detection                 │
│  • /object-detection  • Service Selection                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│               API Gateway REST API                       │
│  • POST /upload-url      → Generate Presigned S3 URL    │
│  • GET /results/{id}     → Get Specific Result          │
│  • GET /results?limit=N  → List Recent Results          │
└────────────────────┬────────────────────────────────────┘
                     │
       ┌─────────────┴──────────────┐
       ▼                            ▼
┌──────────────┐            ┌──────────────┐
│   S3 Bucket  │            │   Lambda     │
│  (Uploads &  │            │  (API Fns)   │
│  Thumbnails) │            └──────────────┘
└──────┬───────┘
       │ Object Created Event
       ▼
┌─────────────────────────────────────────────────────────┐
│              EventBridge Event Bus                       │
│  Routes by S3 prefix:                                    │
│  • text-detection/    → Text Detection Workflow          │
│  • face-detection/    → Face Detection Workflow          │
│  • object-detection/  → Object Detection Workflow        │
│  • All uploads        → Thumbnail Generator              │
└─────────────┬───────────────────────────────────────────┘
              │
    ┌─────────┼─────────┐
    ▼         ▼         ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│  Text    │ │  Face    │ │ Object   │
│  Step    │ │  Step    │ │  Step    │
│ Function │ │ Function │ │ Function │
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     │ Each workflow:          │
     │ 1. Orchestrator (validate)
     │ 2. Detector (analyze)   │
     │ 3. Results Aggregator   │
     │                         │
     └────────────┬────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│                 DynamoDB (3 Tables)                      │
│  • text-detection-results                                │
│  • face-detection-results                                │
│  • object-detection-results                              │
└─────────────────────────────────────────────────────────┘
```

### AWS Services Used

| Service | Purpose | Count |
|---------|---------|-------|
| **S3** | Image storage and frontend hosting | 2 buckets |
| **Lambda** | Serverless compute | 8 functions |
| **Rekognition** | AI-powered image analysis | 3 APIs |
| **Step Functions** | Workflow orchestration | 3 workflows |
| **EventBridge** | Event-driven routing | 4 rules |
| **DynamoDB** | Results storage | 3 tables |
| **API Gateway** | REST API endpoints | 2 routes |
| **CloudWatch** | Logging and monitoring | Auto-enabled |
| **IAM** | Security and permissions | 4 roles |

## Project Structure

```
aws-project/
├── frontend/                          # React SPA (Vite + React 19)
│   ├── src/
│   │   ├── components/               # Reusable UI components
│   │   │   ├── ImageUpload.jsx      # Drag-drop file upload
│   │   │   ├── ResultsDisplay.jsx   # Results visualization
│   │   │   └── ServiceCard.jsx      # Service selection cards
│   │   ├── pages/                   # Service-specific pages
│   │   │   ├── Home.jsx             # Landing page
│   │   │   ├── TextDetection/       # OCR service page
│   │   │   ├── FaceDetection/       # Face analysis page
│   │   │   └── ObjectDetection/     # Object detection page
│   │   ├── services/
│   │   │   └── api.js               # Axios-based API client
│   │   ├── App.jsx                  # Root component with routing
│   │   └── main.jsx                 # Entry point
│   ├── package.json                 # Dependencies
│   └── vite.config.js              # Vite configuration
│
├── lambdas/                          # Python 3.11 Lambda functions
│   ├── orchestrator/                 # Image validation (63 lines)
│   ├── text-detector/                # OCR analysis (86 lines)
│   ├── face-detector/                # Face analysis (72 lines)
│   ├── object-detector/              # Object detection (54 lines)
│   ├── results-aggregator/           # Results storage (145 lines)
│   ├── api-upload-url/               # Presigned URL generator (117 lines)
│   ├── api-get-results/              # Results query API (202 lines)
│   └── thumbnail-generator/          # Image thumbnails with Pillow (87 lines)
│
├── terraform/                        # Infrastructure as Code (1,200+ lines)
│   ├── providers.tf                 # AWS provider configuration
│   ├── variables.tf                 # Configuration variables
│   ├── outputs.tf                   # Stack outputs
│   ├── s3.tf                        # S3 buckets + CORS
│   ├── lambda.tf                    # Analysis Lambda functions
│   ├── api-lambda.tf                # API Lambda functions
│   ├── api-gateway.tf               # REST API configuration
│   ├── api-iam.tf                   # API IAM roles
│   ├── iam.tf                       # Analysis IAM roles
│   ├── step-functions-services.tf   # Service-specific workflows
│   ├── eventbridge-services.tf      # Event routing rules
│   ├── dynamodb-services.tf         # Service-specific tables
│   ├── frontend-hosting.tf          # S3 static website + CloudFront
│   ├── thumbnail-generator.tf       # Thumbnail Lambda config
│   └── terraform.tfstate            # Deployment state
│
├── scripts/
│   ├── deploy-frontend.sh           # Automated frontend deployment
│   └── deploy-frontend-s3.sh        # S3 sync script
│
├── build/                            # Compiled Lambda packages
├── Makefile                          # Build automation (check-deps, deploy, etc.)
├── README.md                         # This file
└── PROJECT_REPORT.md                # Detailed technical documentation
```

## Lambda Functions

### API Functions (2)
- **api-upload-url** - Generates 5-minute presigned S3 URLs with service-specific prefixes
- **api-get-results** - Retrieves results from DynamoDB with pagination and thumbnail URLs

### Processing Functions (5)
- **orchestrator** - Validates uploaded images and extracts S3 metadata
- **text-detector** - Extracts text using Rekognition `detect_text` API
- **face-detector** - Analyzes faces using Rekognition `detect_faces` API
- **object-detector** - Detects objects using Rekognition `detect_labels` API
- **results-aggregator** - Stores combined results in service-specific DynamoDB tables

### Utility Functions (1)
- **thumbnail-generator** - Creates 200x200px thumbnails using Python Pillow library

## Prerequisites

- **AWS Account** with appropriate permissions (Lambda, S3, Rekognition, DynamoDB, etc.)
- **AWS CLI** configured with credentials (`aws configure`)
- **Terraform** >= 1.0
- **Node.js** >= 18 and npm
- **Python** 3.11 (for Lambda functions)
- **Docker** (for packaging Pillow dependencies)
- **Git** for version control

## Quick Start

### Option 1: Using Makefile (Recommended)

```bash
# Check prerequisites
make check-deps

# Deploy everything (backend + frontend)
make deploy

# Or deploy separately:
make deploy-backend    # Terraform infrastructure
make deploy-frontend   # Build and upload React app
```

### Option 2: Manual Deployment

#### 1. Deploy Backend Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- S3 bucket for image uploads and thumbnails
- 8 Lambda functions (5 processing + 2 API + 1 utility)
- 3 Step Functions workflows (one per service)
- 3 DynamoDB tables (one per service)
- 4 EventBridge rules
- API Gateway with 2 routes
- S3 bucket for frontend hosting (+ optional CloudFront)
- All IAM roles and policies

**Note the outputs** - you'll need the API Gateway URL and frontend bucket name.

#### 2. Build and Deploy Frontend

```bash
# Use deployment script (recommended)
./scripts/deploy-frontend-s3.sh

# Or manually:
cd frontend
npm install

# Create .env file with API URL from terraform output
echo "VITE_API_BASE_URL=<your-api-gateway-url>" > .env

# Build and deploy
npm run build
aws s3 sync dist/ s3://<frontend-bucket-name>/ --delete

# If using CloudFront, invalidate cache
aws cloudfront create-invalidation --distribution-id <cloudfront-id> --paths "/*"
```

#### 3. Access Your Application

Get the frontend URL from Terraform outputs:

```bash
terraform -chdir=terraform output frontend_url
```

## Usage

### 1. Select a Service
- Navigate to the home page
- Choose from **Text Detection**, **Face Detection**, or **Object Detection**

### 2. Upload an Image
- Click "Choose an image file" or drag-and-drop
- Supported formats: JPEG, PNG, GIF, BMP, WEBP (max 10MB)
- Click "Upload & Analyze"

### 3. View Results
- Results appear automatically after 2-5 seconds
- See detailed analysis based on selected service:
  - **Text Detection**: Extracted text, line count, word count
  - **Face Detection**: Age range, gender, emotions, facial attributes
  - **Object Detection**: Detected objects with confidence scores

### 4. Browse History
- Service-specific history appears in the right panel
- Thumbnail previews for quick identification
- Click any image to view its full results
- Results are stored permanently in DynamoDB

## API Endpoints

### POST /upload-url
Generate presigned URL for direct S3 upload

**Request:**
```json
{
  "fileName": "document.jpg",
  "fileType": "image/jpeg",
  "service": "text-detection"
}
```

**Response:**
```json
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "imageId": "text-detection/20251121-183045-abc123-document.jpg",
  "service": "text-detection",
  "expiresIn": 300
}
```

### GET /results/{imageId}
Get analysis results for specific image

**Response (Processing):**
```json
{
  "image_id": "text-detection/...",
  "status": "processing",
  "message": "Analysis in progress"
}
```

**Response (Completed):**
```json
{
  "image_id": "text-detection/20251121-183045-abc123-document.jpg",
  "timestamp": "2025-11-21T18:30:45.123Z",
  "status": "completed",
  "service": "text-detection",
  "analysis_summary": {
    "service": "text-detection",
    "text_detected": 5
  },
  "detection_results": {
    "text": {
      "full_text": "Invoice #12345\nTotal: $99.99",
      "lines": [...],
      "line_count": 2,
      "word_count": 4
    }
  },
  "thumbnail_url": "https://s3.amazonaws.com/..."
}
```

### GET /results?limit=N&service=text-detection
List recent uploads with optional filtering

**Response:**
```json
{
  "items": [
    {
      "image_id": "...",
      "timestamp": "...",
      "status": "completed",
      "service": "text-detection",
      "analysis_summary": {...},
      "thumbnail_url": "..."
    }
  ],
  "count": 15
}
```

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

```bash
# Get bucket name
BUCKET=$(terraform -chdir=terraform output -raw bucket_name)

# Upload test image to specific service
aws s3 cp test-image.jpg s3://$BUCKET/text-detection/

# Check Step Functions execution
aws stepfunctions list-executions \
  --state-machine-arn $(terraform -chdir=terraform output -raw text_detection_step_functions_arn)

# Query results from service-specific table
aws dynamodb scan --table-name text-detection-results
```

### Makefile Targets

```bash
make check-deps              # Verify prerequisites installed
make install-frontend        # Install frontend dependencies
make build-frontend          # Build React application
make install-thumbnail-deps  # Package Pillow with Docker
make terraform-init          # Initialize Terraform
make terraform-plan          # Preview infrastructure changes
make terraform-apply         # Deploy backend infrastructure
make deploy-frontend         # Build and deploy frontend
make deploy-backend          # Alias for terraform-apply
make deploy                  # Full deployment (backend + frontend)
make clean                   # Remove build artifacts
make destroy                 # Destroy all infrastructure
```

## Cost Estimation

### Per 1000 Images Analyzed:

| Service | Usage | Cost |
|---------|-------|------|
| **Lambda** | 8 functions × ~1s each | $0.02 |
| **Step Functions** | State transitions | $0.03 |
| **Rekognition** | 3 API calls per image | $1.50 |
| **DynamoDB** | Writes + reads | $0.25 |
| **S3** | Storage + requests | $0.02 |
| **Data Transfer** | Outbound | $0.10 |
| **Total** | | **~$2.00** |

*Plus free tier benefits for the first 12 months*

## Configuration

Edit `terraform/variables.tf` to customize:

```hcl
variable "aws_region" {
  default = "us-east-1"  # Change deployment region
}

variable "environment" {
  default = "dev"  # Environment tag
}

variable "lambda_memory_size" {
  default = 128  # Increase for faster processing
}

variable "lambda_timeout" {
  default = 30  # Maximum execution time (seconds)
}

variable "dynamodb_billing_mode" {
  default = "PAY_PER_REQUEST"  # Or "PROVISIONED"
}
```

## Monitoring

### CloudWatch Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/orchestrator --follow
aws logs tail /aws/lambda/text-detector --follow
aws logs tail /aws/lambda/api-upload-url --follow

# View Step Functions executions
aws stepfunctions list-executions \
  --state-machine-arn $(terraform -chdir=terraform output -raw text_detection_step_functions_arn) \
  --max-results 10
```

### Key Metrics

- Lambda invocations, duration, errors
- Step Functions execution success/failure rates
- API Gateway request counts, latency, 4xx/5xx errors
- DynamoDB read/write capacity consumption
- S3 bucket size and request metrics
- Rekognition API call counts

## Troubleshooting

### Images not processing
1. Check EventBridge rule is enabled: `aws events list-rules`
2. Verify S3 bucket notifications: `aws s3api get-bucket-notification-configuration --bucket <bucket-name>`
3. Check Step Functions execution history in AWS Console
4. Review Lambda CloudWatch logs for errors

### Frontend can't upload
1. Verify API Gateway URL in `.env` file
2. Check S3 CORS configuration in `terraform/s3.tf`
3. Ensure API Lambda has S3 PutObject permissions
4. Check browser console for CORS or network errors

### Results not appearing
1. Wait 5-10 seconds for processing to complete
2. Check DynamoDB tables for entries: `aws dynamodb scan --table-name text-detection-results`
3. Verify Lambda has DynamoDB PutItem permissions
4. Review api-get-results Lambda CloudWatch logs

### Thumbnail generation failing
1. Check thumbnail-generator Lambda logs
2. Verify Pillow dependencies are packaged correctly
3. Ensure Lambda has S3 GetObject and PutObject permissions
4. Check S3 bucket structure for `thumbnails/` prefix

## Data Flow

### 1. Upload Flow
```
User selects image + service
  → Frontend requests presigned URL (POST /upload-url)
  → API Lambda generates S3 URL with service prefix
  → Frontend uploads directly to S3
  → S3 emits "Object Created" event
  → EventBridge routes to service workflow
```

### 2. Processing Flow
```
EventBridge triggers Step Function
  → Orchestrator validates image
  → Service-specific detector calls Rekognition
  → Results Aggregator stores in DynamoDB
  → Thumbnail Generator creates 200x200px preview (parallel)
```

### 3. Retrieval Flow
```
Frontend polls GET /results/{imageId}
  → API Lambda queries service-specific DynamoDB table
  → Returns results with thumbnail presigned URL
  → Frontend displays formatted results
```

## Security Considerations

### Production Recommendations:

1. **CORS** - Restrict S3/API CORS to your domain only
   ```hcl
   allowed_origins = ["https://yourdomain.com"]
   ```

2. **API Gateway** - Add authentication
   - AWS Cognito User Pools
   - API Keys with usage plans
   - Lambda authorizers

3. **CloudFront** - Use custom domain with SSL
   - ACM certificate
   - HTTPS-only policy
   - Geo-restriction if needed

4. **IAM** - Review and tighten Lambda permissions
   - Apply least privilege principle
   - Use resource-specific policies

5. **S3** - Enable additional protections
   - Versioning for disaster recovery
   - Lifecycle policies for cost optimization
   - Block public access (already enabled)

6. **DynamoDB** - Enable security features
   - Point-in-time recovery (already enabled)
   - Encryption at rest (already enabled)
   - VPC endpoints for private access

7. **Rate Limiting** - Add API Gateway throttling
   - Set burst and rate limits
   - Implement per-user quotas

8. **Monitoring** - Set up CloudWatch alarms
   - Lambda errors and timeouts
   - API Gateway 4xx/5xx rates
   - Unexpected cost spikes

## Cleanup

To destroy all resources and avoid charges:

```bash
# Option 1: Using Makefile
make destroy

# Option 2: Manual cleanup
# Empty S3 buckets first (Terraform can't delete non-empty buckets)
aws s3 rm s3://$(terraform -chdir=terraform output -raw bucket_name) --recursive
aws s3 rm s3://$(terraform -chdir=terraform output -raw frontend_bucket_name) --recursive

# Destroy infrastructure
cd terraform
terraform destroy
```

## Technology Stack

### Frontend
- **React** 19.2.0 - UI framework
- **React Router** 7.9.6 - Client-side routing
- **Axios** 1.13.2 - HTTP client
- **Vite** 7.2.2 - Build tool and dev server

### Backend
- **Python** 3.11 - Lambda runtime
- **Boto3** - AWS SDK for Python
- **Pillow** - Image processing library

### Infrastructure
- **Terraform** - Infrastructure as Code
- **AWS CLI** - Deployment automation
- **Docker** - Lambda dependency packaging

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues or questions:
- Check the [PROJECT_REPORT.md](./PROJECT_REPORT.md) for detailed documentation
- Review CloudWatch logs for error details
- Open a GitHub issue with:
  - Description of the problem
  - Steps to reproduce
  - Relevant logs or error messages
  - Your AWS region and Terraform version

## Additional Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS Rekognition Documentation](https://docs.aws.amazon.com/rekognition/)
- [AWS Step Functions Documentation](https://docs.aws.amazon.com/step-functions/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)

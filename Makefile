.PHONY: help check-deps install-frontend build-frontend install-thumbnail-deps terraform-init terraform-plan terraform-apply deploy-frontend deploy-backend deploy clean destroy clean-frontend clean-terraform

# Default target
.DEFAULT_GOAL := help

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Project paths
FRONTEND_DIR := frontend
TERRAFORM_DIR := terraform
SCRIPTS_DIR := scripts

help: ## Show this help message
	@printf "$(BLUE)AWS Image Analysis Platform - Makefile$(NC)\n"
	@printf "\n"
	@printf "$(GREEN)Available targets:$(NC)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@printf "\n"

check-deps: ## Check if all required dependencies are installed
	@printf "$(BLUE)Checking dependencies...$(NC)\n"
	@printf "AWS CLI: "; command -v aws >/dev/null 2>&1 && printf "$(GREEN)✓$(NC)\n" || printf "$(YELLOW)✗ Not found$(NC)\n"
	@printf "Terraform: "; command -v terraform >/dev/null 2>&1 && printf "$(GREEN)✓$(NC)\n" || printf "$(YELLOW)✗ Not found$(NC)\n"
	@printf "Node.js: "; command -v node >/dev/null 2>&1 && printf "$(GREEN)✓$(NC)\n" || printf "$(YELLOW)✗ Not found$(NC)\n"
	@printf "npm: "; command -v npm >/dev/null 2>&1 && printf "$(GREEN)✓$(NC)\n" || printf "$(YELLOW)✗ Not found$(NC)\n"
	@printf "\n"
	@if command -v aws >/dev/null 2>&1 && command -v terraform >/dev/null 2>&1 && command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then \
		printf "$(GREEN)✓ All dependencies are installed! Ready to deploy.$(NC)\n"; \
	else \
		printf "$(YELLOW)ERROR: Some dependencies are missing. Please install them before deployment.$(NC)\n"; \
		exit 1; \
	fi

install-frontend: ## Install frontend dependencies
	@printf "$(BLUE)Installing frontend dependencies...$(NC)\n"
	cd $(FRONTEND_DIR) && npm install
	@printf "$(GREEN)✓ Frontend dependencies installed$(NC)\n"

build-frontend: install-frontend ## Build frontend for production
	@printf "$(BLUE)Building frontend...$(NC)\n"
	cd $(FRONTEND_DIR) && npm run build
	@printf "$(GREEN)✓ Frontend built successfully$(NC)\n"

install-thumbnail-deps: ## Install thumbnail generator dependencies using Docker
	@printf "$(BLUE)Installing thumbnail generator dependencies...$(NC)\n"
	docker run --rm -v $(PWD)/lambdas/thumbnail-generator:/var/task python:3.11-slim pip install -r /var/task/requirements.txt -t /var/task
	@printf "$(GREEN)✓ Dependencies installed$(NC)\n"

terraform-init: ## Initialize Terraform
	@printf "$(BLUE)Initializing Terraform...$(NC)\n"
	cd $(TERRAFORM_DIR) && terraform init
	@printf "$(GREEN)✓ Terraform initialized$(NC)\n"

terraform-plan: terraform-init ## Run Terraform plan
	@printf "$(BLUE)Planning Terraform changes...$(NC)\n"
	cd $(TERRAFORM_DIR) && terraform plan
	@printf "$(GREEN)✓ Terraform plan complete$(NC)\n"

terraform-apply: terraform-init ## Apply Terraform infrastructure
	@printf "$(BLUE)Applying Terraform infrastructure...$(NC)\n"
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve
	@printf "$(GREEN)✓ Infrastructure deployed$(NC)\n"

deploy-frontend: build-frontend ## Deploy frontend to S3 and invalidate CloudFront
	@printf "$(BLUE)Deploying frontend...$(NC)\n"
	@if [ ! -f $(TERRAFORM_DIR)/terraform.tfstate ]; then \
		printf "$(YELLOW)Warning: Terraform state not found. Please run 'make deploy-backend' first.$(NC)\n"; \
		exit 1; \
	fi
	@chmod +x $(SCRIPTS_DIR)/deploy-frontend-s3.sh
	./$(SCRIPTS_DIR)/deploy-frontend-s3.sh
	@printf "$(GREEN)✓ Frontend deployed$(NC)\n"

deploy-backend: terraform-apply ## Deploy complete backend infrastructure
	@printf "$(GREEN)✓ Backend deployment complete$(NC)\n"

deploy: check-deps deploy-backend deploy-frontend ## Full deployment - backend + frontend
	@printf "\n"
	@printf "$(GREEN)═══════════════════════════════════════════════$(NC)\n"
	@printf "$(GREEN)✓ Complete deployment finished successfully!$(NC)\n"
	@printf "$(GREEN)═══════════════════════════════════════════════$(NC)\n"
	@printf "\n"
#	@printf "$(BLUE)Your application is available at:$(NC)\n"
#	@cd $(TERRAFORM_DIR) && terraform output -raw cloudfront_url 2>/dev/null || printf "Run 'terraform output cloudfront_url' to get URL\n"
#	@printf "\n"

all: deploy ## Alias for 'deploy' - complete build and deployment

clean-frontend: ## Clean frontend build artifacts
	@printf "$(BLUE)Cleaning frontend build...$(NC)\n"
	rm -rf $(FRONTEND_DIR)/dist
	rm -rf $(FRONTEND_DIR)/node_modules
	rm -f $(FRONTEND_DIR)/.env
	@printf "$(GREEN)✓ Frontend cleaned$(NC)\n"

clean-terraform: ## Clean Terraform files and build directory
	@printf "$(BLUE)Cleaning Terraform artifacts...$(NC)\n"
	rm -rf build
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	@printf "$(GREEN)✓ Terraform artifacts cleaned$(NC)\n"

clean: clean-frontend clean-terraform ## Clean all build artifacts
	@printf "$(GREEN)✓ All build artifacts cleaned$(NC)\n"

destroy: ## Destroy all AWS infrastructure (requires confirmation)
	@printf "$(YELLOW)WARNING: This will destroy all AWS resources!$(NC)\n"
	@printf "$(YELLOW)Emptying S3 buckets first...$(NC)\n"
	@if [ -f $(TERRAFORM_DIR)/terraform.tfstate ]; then \
		BUCKET=$$(cd $(TERRAFORM_DIR) && terraform output -raw bucket_name 2>/dev/null) && \
		FRONTEND_BUCKET=$$(cd $(TERRAFORM_DIR) && terraform output -raw frontend_bucket_name 2>/dev/null) && \
		if [ -n "$$BUCKET" ]; then \
			printf "Emptying uploads bucket: $$BUCKET\n"; \
			aws s3 rm s3://$$BUCKET --recursive 2>/dev/null || true; \
		fi && \
		if [ -n "$$FRONTEND_BUCKET" ]; then \
			printf "Emptying frontend bucket: $$FRONTEND_BUCKET\n"; \
			aws s3 rm s3://$$FRONTEND_BUCKET --recursive 2>/dev/null || true; \
		fi; \
	fi
	@printf "$(BLUE)Destroying Terraform infrastructure...$(NC)\n"
	cd $(TERRAFORM_DIR) && terraform destroy
	@printf "$(GREEN)✓ Infrastructure destroyed$(NC)\n"

# Development helpers
dev-frontend: install-frontend ## Start frontend development server
	@printf "$(BLUE)Starting frontend dev server...$(NC)\n"
	@if [ ! -f $(FRONTEND_DIR)/.env ]; then \
		printf "$(YELLOW)Warning: .env file not found. Creating template...$(NC)\n"; \
		printf "VITE_API_BASE_URL=https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod\n" > $(FRONTEND_DIR)/.env; \
		printf "$(YELLOW)Please update $(FRONTEND_DIR)/.env with your actual API Gateway URL$(NC)\n"; \
	fi
	cd $(FRONTEND_DIR) && npm run dev

outputs: ## Show Terraform outputs
	@printf "$(BLUE)Terraform Outputs:$(NC)\n"
	@cd $(TERRAFORM_DIR) && terraform output

test-backend: ## Test backend by uploading a test image
	@printf "$(BLUE)Testing backend...$(NC)\n"
	@BUCKET=$$(cd $(TERRAFORM_DIR) && terraform output -raw bucket_name) && \
	printf "Upload bucket: $$BUCKET\n" && \
	printf "To test, upload an image:\n" && \
	printf "  aws s3 cp your-image.jpg s3://$$BUCKET/\n" && \
	printf "Then check Step Functions:\n" && \
	printf "  aws stepfunctions list-executions --state-machine-arn $$(cd $(TERRAFORM_DIR) && terraform output -raw step_functions_arn)\n"

status: ## Show deployment status
	@printf "$(BLUE)Deployment Status:$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)Frontend:$(NC)\n"
	@if [ -d $(FRONTEND_DIR)/dist ]; then \
		printf "  ✓ Built\n"; \
	else \
		printf "  ✗ Not built\n"; \
	fi
	@if [ -d $(FRONTEND_DIR)/node_modules ]; then \
		printf "  ✓ Dependencies installed\n"; \
	else \
		printf "  ✗ Dependencies not installed\n"; \
	fi
	@printf "\n"
	@printf "$(YELLOW)Backend:$(NC)\n"
	@if [ -f $(TERRAFORM_DIR)/terraform.tfstate ]; then \
		printf "  ✓ Infrastructure deployed\n"; \
		cd $(TERRAFORM_DIR) && terraform output -json > /dev/null 2>&1 && printf "  ✓ Terraform outputs available\n" || printf "  ✗ Terraform outputs unavailable\n"; \
	else \
		printf "  ✗ Infrastructure not deployed\n"; \
	fi
	@printf "\n"

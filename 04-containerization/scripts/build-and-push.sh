#!/bin/bash
# =============================================================================
# Build and Push Docker Images to ECR
# =============================================================================
# Usage: ./build-and-push.sh [backend|frontend|all]

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-taskflow}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Building and Pushing Docker Images to ECR${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Registry: $ECR_REGISTRY"
echo ""

# Login to ECR
login_ecr() {
    echo -e "${YELLOW}Logging in to ECR...${NC}"
    aws ecr get-login-password --region $AWS_REGION | \
        docker login --username AWS --password-stdin $ECR_REGISTRY
    echo -e "${GREEN}✓ Logged in to ECR${NC}"
    echo ""
}

# Build and push backend
build_backend() {
    echo -e "${YELLOW}Building backend image...${NC}"

    BACKEND_REPO="${ECR_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-backend"
    BACKEND_DIR="${PROJECT_ROOT}/00-local-development/backend"

    cd "$BACKEND_DIR"

    # Build with tag (--platform for cross-architecture builds on Apple Silicon)
    docker build --platform linux/amd64 -t "${BACKEND_REPO}:latest" -f Dockerfile.prod .
    docker tag "${BACKEND_REPO}:latest" "${BACKEND_REPO}:$(date +%Y%m%d-%H%M%S)"

    echo -e "${YELLOW}Pushing backend image...${NC}"
    docker push "${BACKEND_REPO}:latest"

    echo -e "${GREEN}✓ Backend image pushed to ${BACKEND_REPO}:latest${NC}"
    echo ""
}

# Build and push frontend
build_frontend() {
    echo -e "${YELLOW}Building frontend image...${NC}"

    FRONTEND_REPO="${ECR_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-frontend"
    FRONTEND_DIR="${PROJECT_ROOT}/00-local-development/frontend"

    cd "$FRONTEND_DIR"

    # Build with tag (pass API URL for production, --platform for Apple Silicon)
    docker build \
        --platform linux/amd64 \
        --build-arg VITE_API_URL=/api \
        -t "${FRONTEND_REPO}:latest" \
        -f Dockerfile.prod .
    docker tag "${FRONTEND_REPO}:latest" "${FRONTEND_REPO}:$(date +%Y%m%d-%H%M%S)"

    echo -e "${YELLOW}Pushing frontend image...${NC}"
    docker push "${FRONTEND_REPO}:latest"

    echo -e "${GREEN}✓ Frontend image pushed to ${FRONTEND_REPO}:latest${NC}"
    echo ""
}

# Main
main() {
    local target="${1:-all}"

    login_ecr

    case $target in
        backend)
            build_backend
            ;;
        frontend)
            build_frontend
            ;;
        all)
            build_backend
            build_frontend
            ;;
        *)
            echo -e "${RED}Usage: $0 [backend|frontend|all]${NC}"
            exit 1
            ;;
    esac

    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}✓ All images built and pushed successfully!${NC}"
    echo -e "${GREEN}================================================${NC}"
}

main "$@"

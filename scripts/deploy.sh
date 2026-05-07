#!/usr/bin/env bash
#
# Manual deploy: build, push to ECR, force ECS service redeploy.
# Mirrors what .github/workflows/deploy.yml does, for local dry-runs and
# emergency redeploys when CI is unavailable.
#
# Required env (export or pass inline):
#   AWS_REGION       e.g. eu-west-1
#   AWS_ACCOUNT_ID   12-digit account id
#   ECR_REPOSITORY   repository name (no registry prefix)
#   ECS_CLUSTER      cluster name
#   ECS_SERVICE      service name
# Optional:
#   IMAGE_TAG        defaults to short git SHA

set -euo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID is required}"
: "${ECR_REPOSITORY:?ECR_REPOSITORY is required}"
: "${ECS_CLUSTER:?ECS_CLUSTER is required}"
: "${ECS_SERVICE:?ECS_SERVICE is required}"

IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "==> Logging into ECR (${REGISTRY})"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "==> Building image ${IMAGE}"
# linux/amd64 because Fargate runs amd64 by default; building from an M-series
# Mac without --platform produces an arm64 image that won't start on ECS.
docker build --platform linux/amd64 -t "$IMAGE" -t "${REGISTRY}/${ECR_REPOSITORY}:latest" .

echo "==> Pushing ${IMAGE}"
docker push "$IMAGE"
docker push "${REGISTRY}/${ECR_REPOSITORY}:latest"

echo "==> Forcing new deployment on ${ECS_CLUSTER}/${ECS_SERVICE}"
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --force-new-deployment \
  --no-cli-pager > /dev/null

echo "==> Waiting for service to stabilise (this can take a few minutes)"
aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE"

echo "==> Deployed ${IMAGE_TAG}"

#!/bin/bash
set -e

echo "Deploying CI/CD Pipeline Infrastructure to AWS..."

if [ -f "../.env" ]; then
    export $(grep -v '^#' ../.env | xargs)
elif [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

MAIN_STACK=${MAIN_STACK:-"ci-cd-main-stack"}
ENV_NAME=${ENVIRONMENT_NAME:-"ci-cd-pipeline"}
PORT=${APP_PORT:-80}
CLUSTER_NAME=${ECS_CLUSTER_NAME:-"ci-cd-pipeline-cluster"}

echo "Deploying Unified Stack ($MAIN_STACK)..."
aws cloudformation deploy \
  --template-file cloudformation/main.yml \
  --stack-name $MAIN_STACK \
  --parameter-overrides EnvironmentName=$ENV_NAME AppPort=$PORT EcsClusterName=$CLUSTER_NAME \
  --capabilities CAPABILITY_NAMED_IAM

echo "Deployment completed successfully!"

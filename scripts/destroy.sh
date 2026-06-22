#!/bin/bash
set -e

echo "Destroying CI/CD Pipeline Infrastructure on AWS..."

if [ -f "../.env" ]; then
    export $(grep -v '^#' ../.env | xargs)
elif [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

MAIN_STACK=${MAIN_STACK:-"ci-cd-main-stack"}

echo "Deleting Unified Stack ($MAIN_STACK)..."
aws cloudformation delete-stack --stack-name $MAIN_STACK
aws cloudformation wait stack-delete-complete --stack-name $MAIN_STACK

echo "Infrastructure destruction completed successfully!"

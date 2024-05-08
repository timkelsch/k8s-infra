#!/bin/bash
set -euxo pipefail

export AWS_PROFILE=k8s
STACK_NAME="terraform-bootstrap"
# Retrieve the backend bucket name from AWS CloudFormation
BACKEND_BUCKET=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='StateBucketName'].OutputValue" \
  --profile=k8s --output text)
STATE_TABLE=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='LockTableName'].OutputValue" \
  --profile=k8s --output text)
BACKEND_BUCKET_KEY="thekubeground"

# Create the key
aws s3api put-object --bucket "${BACKEND_BUCKET}" --key "${BACKEND_BUCKET_KEY}" --content-length 0 --profile=k8s

cat << EOF > backend.tf
terraform {
  backend "s3" {
    bucket         = "${BACKEND_BUCKET}"
    key            = "${BACKEND_BUCKET_KEY}"
    dynamodb_table = "${STATE_TABLE}"
    region         = "us-west-2" # Oregon
  }
}
EOF


terraform init -reconfigure
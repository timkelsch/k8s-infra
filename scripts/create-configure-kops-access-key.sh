#!/bin/bash

set -euxo pipefail

TARGET_AWS_USER=kops
export AWS_PROFILE=kubeground-admin
export AWS_DEFAULT_OUTPUT=json

# if the kops aws profile already exists, exit
if aws configure list-profiles | grep '^'"${TARGET_AWS_USER}"'$'; then
    echo "kops profile already exists. Delete it if you want to recreate it."
    exit 1
fi

cd ..
AWS_REGION=$(terraform output aws_region | tr -d '"')
CORRECT_AWS_ACCOUNT_ID=$(terraform output account_id | tr -d '"')
CORRECT_AWS_USER=$(terraform output caller_arn | cut -d '/' -f 2 | tr -d '"')

CURRENT_AWS_USER_INFO=$(aws sts get-caller-identity)
CURRENT_AWS_USER=$(echo "${CURRENT_AWS_USER_INFO}" | jq -r '.Arn' | cut -d '/' -f 2)
CURRENT_AWS_ACCOUNT_ID=$(echo "${CURRENT_AWS_USER_INFO}" | jq -r '.Account')

if [[ ${CURRENT_AWS_USER} != ${CORRECT_AWS_USER} ]] || \
  [[ ${CURRENT_AWS_ACCOUNT_ID} != ${CORRECT_AWS_ACCOUNT_ID} ]]; then
    echo "You are not using the correct user or account."
    echo "Current User: ${CURRENT_AWS_USER}"
    echo "Correct User: ${CORRECT_AWS_USER}"
    echo "Current Account: ${CURRENT_AWS_ACCOUNT_ID}"
    echo "Correct Account: ${CORRECT_AWS_ACCOUNT_ID}"
    exit 1
fi

# Create the kops access key and set the output to a json variable
set +x
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name ${TARGET_AWS_USER})

# TODO: disable and delete any other access keys for the kops user

# Parse out the json into access key and secret key
ACCESS_KEY_ID=$(echo "${ACCESS_KEY_OUTPUT}" | jq -r '.AccessKey.AccessKeyId')
ACCESS_KEY_SECRET=$(echo "${ACCESS_KEY_OUTPUT}" | jq -r '.AccessKey.SecretAccessKey')

# run the aws configure commands to set the access key and secret key for the kops user
aws configure set profile.${TARGET_AWS_USER}.aws_secret_access_key "${ACCESS_KEY_SECRET}"
set -x
aws configure set profile.${TARGET_AWS_USER}.aws_access_key_id "${ACCESS_KEY_ID}"
aws configure set profile.${TARGET_AWS_USER}.region "${AWS_REGION}"
aws configure set profile.${TARGET_AWS_USER}.output json

sleep 5
aws sts get-caller-identity --profile ${TARGET_AWS_USER}
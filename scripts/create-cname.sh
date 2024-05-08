#!/bin/bash

if [[ ${PWD##*/} != *scrips ]]; then
  echo "This script must be run from the scripts directory"
fi

set -euxo pipefail

HOSTED_ZONE_NAME='thekubeground.com.'
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name thekubeground.com \
  --output json --query 'HostedZones[?Name==`'"${HOSTED_ZONE_NAME}"'`].Id' | \
  grep hosted | tr -d '"' | cut -d/ -f3)

# only works if you have one ingress. can't think of a great way to get the 
# data necessary to query for the right ingress without using helm to kick 
# off the deployment.

TARGET_URL=$(kubectl get ingress -n gonzo thekubeground-ingress \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
DOMAIN_NAME=www.thekubeground.com.
FILE_NAME=cname.json
ACTION=CREATE

# rather than implement a mechanism to whack the CNAME when the kops cluster
# is destroyed, we'll just UPSERT the CNAME if it already exists
if aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID}" \
  --query 'ResourceRecordSets[?Name==`'"${DOMAIN_NAME}"'`]'; then
  ACTION=UPSERT
fi

cat > ${FILE_NAME} << EOL
{
  "Changes": [
    {
      "Action": "${ACTION}",
      "ResourceRecordSet": {
        "Name": "${DOMAIN_NAME}",
        "Type": "CNAME",
        "TTL": 30,
        "ResourceRecords": [
          { "Value": "${TARGET_URL}" }
        ]
      }
    }
  ]
}
EOL

cat ${FILE_NAME}

aws route53 change-resource-record-sets \
    --hosted-zone-id "${ZONE_ID}" \
    --change-batch file://${FILE_NAME}

if [ -f ${FILE_NAME} ]; then
  rm -f ${FILE_NAME}
fi

# Implement status check later if needed since it's an async call
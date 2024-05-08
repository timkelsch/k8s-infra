#!/bin/bash

if [[ ${PWD##*/} != *scrips ]]; then
  echo "This script must be run from the scripts directory"
fi

set -euxo pipefail
HOSTED_ZONE_NAME='thekubeground.com.'
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name thekubeground.com \
  --output json --query 'HostedZones[?Name==`'"${HOSTED_ZONE_NAME}"'`].Id' | \
  grep hosted | tr -d '"' | cut -d/ -f3)
TARGET_DOMAIN='a27159951b4dd4741b8bf009c98e4da5-570854217.us-west-2.elb.amazonaws.com'
DOMAIN_NAME=www.thekubeground.com
FILE_NAME=cname.json

cat > ${FILE_NAME} << EOL
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "${DOMAIN_NAME}",
        "Type": "CNAME",
        "TTL": 30,
        "ResourceRecords": [
          { "Value": "${TARGET_DOMAIN}" }
        ]
      }
    }
  ]
}
EOL

aws route53 change-resource-record-sets \
    --hosted-zone-id "${ZONE_ID}" \
    --change-batch file://${FILE_NAME}

if [ -f ${FILE_NAME} ]; then
  rm -f ${FILE_NAME}
fi

# Implement status check later if needed since it's an async call
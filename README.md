# k8s-infra


Completed Tasks:
1. Remove account ID from tf-bootstrap for security reasons


Build from Scratch:
1. Configure AWS CLI profile to connect to the right account and region
1. Trigger the terraform bootstrap:
    ```cd tf-bootstrap && make create-stack```
1. Install kubectl
1. Install kOps
1. Create new hosted zone for k8s-pg.timkelsch.com
    ```
    ID=$(uuidgen) && aws route53 create-hosted-zone \
    --name k8s-pg.timkelsch.com --caller-reference $ID
    ```
1. Put the NameServers into ./tf-bootstrap/subdomain.json
1. Look up the PARENT hosted zone ID:
    ```
    aws route53 list-hosted-zones | \
    jq '.HostedZones[]' | \
    select(.Name=="timkelsch.com.")
    ```
1. Apply the subdomain NS records to the parent hosted zone:
    ```
    aws route53 change-resource-record-sets \
    --hosted-zone-id Z07419102HFRMCTH28NVX \
    --change-batch file://subdomain.json
    ```

# k8s-infra


Completed Tasks:
1. Remove account ID from tf-bootstrap for security reasons


Build from Scratch in New Account:
1. Configure AWS CLI profile to connect to the right account and region
1. Trigger the terraform bootstrap (uses CloudFormation):
    ```cd tf-bootstrap && make create-stack```
1. 
1. Bootstrap the kOps infrastructure. Set variables.tf:deploy_kops-bootstrap=true
    ```
    terraform apply
    ```
1. Manually create an access key for the kops user, run `aws configure`, and run `export AWS_PROFILE=kops`.
1. Create kOps cluster config:
    ```
    export NAME='k8s-pg.timkelsch.com' && \
    export KOPS_STATE_STORE="kops-cluster-state-ffbf22bd9e96206c" \ 
    # s3://$(terraform output kops_cluster_state_s3-bucket_name | jq -r)" && \
    kops create cluster \
    --name="${NAME}" \
    --cloud=aws \
    --zones=$(aws ec2 describe-availability-zones --region $(aws configure get region) \
      --query 'AvailabilityZones[?State==`available`] | [0].ZoneName') \
    --discovery-store="s3://oidc-ffbf22bd9e96206c/${NAME}/discovery"
    ```
1. Create k8s cluster via kOps:
    ```
    kops update cluster --name "${NAME}" --yes --admin
    ```

Build from Scratch in Personal Account:
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
1. Bootstrap the kOps infrastructure. Set variables.tf:deploy_kops-bootstrap=true
    ```
    terraform apply
    ```
1. Manually create an access key for the kops user, run `aws configure`, and run `export AWS_PROFILE=kops`.
1. Create kOps cluster config:
    ```
    export NAME='k8s-pg.timkelsch.com' && \
    export KOPS_STATE_STORE="kops-cluster-state-ffbf22bd9e96206c" \ 
    # s3://$(terraform output kops_cluster_state_s3-bucket_name | jq -r)" && \
    kops create cluster \
    --name="${NAME}" \
    --cloud=aws \
    --zones=$(aws ec2 describe-availability-zones --region $(aws configure get region) \
      --query 'AvailabilityZones[?State==`available`] | [0].ZoneName') \
    --discovery-store="s3://oidc-ffbf22bd9e96206c/${NAME}/discovery"
    ```
1. Create k8s cluster via kOps:
    ```
    kops update cluster --name "${NAME}" --yes --admin
    ```
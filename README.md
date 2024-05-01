# k8s-infra

Build from Scratch in Dedicated Account with Dedicated Domain:
1. Configure AWS CLI profile to connect to the right account and region
1. Trigger the terraform bootstrap:
    ```cd tf-bootstrap && make create-stack```
1. Install kubectl
1. Install kOps
1. Bootstrap the kOps infrastructure. Set variables.tf:deploy_kops-bootstrap=true
    ```
    terraform apply
    ```
1. Manually create an access key for the kops user, run `aws configure`, and run `export AWS_PROFILE=kops`.
1. Create kOps cluster config:
    ```
    make create-cluster
    ```
1. Add our SSH key:
    ```
    make add-ssh-key
    ```
1. Create k8s cluster via kOps:
    ```
    make update-cluster-execute
    ```
1. Fix the kubeconfig:
    ```
    kops export kubeconfig --admin
    ```
1. Log in to the control-plane node:
    ```
    sshk # ssh -i ~/.ssh/v1.pem ubuntu@api.thekubeground.com
    ```
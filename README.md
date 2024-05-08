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
    make build-cluster
    ```
1. Fix the kubeconfig:
    ```
    kops export kubeconfig --admin
    ```
1. Log in to the control-plane node:
    ```
    sshk # ssh -i ~/.ssh/v1.pem ubuntu@api.thekubeground.com
    ```

Create a Service and Expose it to the Internet via NGINX Ingress Controller:
1. Install the Nginx Ingress Controller via Helm:
    ```
    make install-nginx-ic
    ```
2. Deploy pod, service, ingress resources
    ```
    make deploy-application
    ```
3. Create the CNAME record linking www.thekubeground.com with our AWS CLB.
    ```
    make generate-cname
    ```


Create a Service and Expose it to Internet via AWS Load Balancer Controller:
1. Fix the aws-cluster-controller inline role policy:
    ```
    make update-aws-cluster-controller-policy
    ```
1. Set the IMDS hops:
    ```
    make set-imds-hops
    ```
1. Log into the control plane node:
    ```
    sshk # ssh -i ~/.ssh/v1.pem ubuntu@api.thekubeground.com
    ```
1. Create a web server:
    ```
    k run nginx --image nginx --port 80
    ```
1. Expose the pod with a LoadBalancer service:
    ```
    k expose pod nginx --name=nginx-svc --type=LoadBalancer
    ```
1. Verify your work:
    ```
    make check-website
    ```

Tasks:
1. Automate all these steps in a CI/CD pipeline.

Completed Tasks:
1. Manifests for pod, service, and ingress are written and automated.
1. DNS requirements are automated
1. cert-manager auto-generates certs when an ingress resource is created
1. Implemented manual cluster backup
1. Got aws-load-balancer-controller working

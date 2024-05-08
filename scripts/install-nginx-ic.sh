#!/bin/bash

set -euxo pipefail

# check if helm is installed and exit if not
if ! command -v helm &> /dev/null
then
    echo "helm could not be found"
    exit
fi

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

if ! helm list --deployed -q | grep quickstart > /dev/null 2>&1; then
    helm install quickstart ingress-nginx/ingress-nginx
else 
    echo "nginx-ingress-controller already installed"
fi

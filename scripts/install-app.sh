#!/bin/bash

set -euxo pipefail

K=$(which kubectl)
NAMESPACE="gonzo"

# preventing it from being run in the root dir of the git repo
# because we need to be able to run it on the k8s nodes
# and only allowing it to run in the scripts directory wouldn't work
if [[ ${PWD##*/} == *k8s-infra ]]; then
  echo "This script must be run from the scripts directory"
fi

${K} get namespace ${NAMESPACE} || ${K} create namespace ${NAMESPACE}

deploy () {
  NAME=$(yq -r '.metadata.name' "$1")
  TYPE=$(yq -r '.kind' "$1")
  if yq -r '.metadata.namespace' "$1"; then
    NS=$(yq -r '.metadata.namespace' "$1")
  else
    NS=default
  fi

  if ! ${K} get "${TYPE}" -n "${NS}" "${NAME}" > /dev/null 2>&1; then
    ${K} apply -f "$1"
  else  
    echo "${TYPE} ${NAME} already exists in ${NS} namespace"
  fi
}

deploy ../manifests/nginx-pod.yml
deploy ../manifests/gonzo-svc.yml
deploy ../manifests/cert-manager/issuer.yml
deploy ../manifests/ingress.yml


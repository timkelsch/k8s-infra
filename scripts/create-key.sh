#!/bin/bash

set -euxo pipefail

KEY=key.pem

openssl genrsa 2048 > "${KEY}"

# Create secret if it does not exist
if ! kubectl get secret letsencrypt-secret; then
  kubectl create secret generic letsencrypt-secret --from-file=key="${KEY}"
fi

if [ -f "${KEY}" ]; then
  rm "${KEY}"
fi
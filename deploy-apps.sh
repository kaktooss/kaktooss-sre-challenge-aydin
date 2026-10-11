#!/bin/bash
set -e # Exit immediately if a build step fails

VERSION="${1:?Version is required. Usage: $0 <version>}"
echo "Using version: $VERSION"

# For Back-App (Writes to the DB)
kubectl create ns demo-back --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic postgres-secret \
  --namespace demo-back \
  --from-literal=postgres-password='54acci4yRWBy' \
  --dry-run=client -o yaml | kubectl apply -f -

# For Reader-App (Reads from the DB)
kubectl create ns demo-reader --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic postgres-secret \
  --namespace demo-reader \
  --from-literal=postgres-password='90acci4yRWDm' \
  --dry-run=client -o yaml | kubectl apply -f -

# TLS Certs
## demo-front cert
if [[ -f ./certs/demo-front.local.pem && -f ./certs/demo-front.local-key.pem ]]; then
  kubectl create secret tls demo-front-tls \
    -n demo-front \
    --cert=./certs/demo-front.local.pem \
    --key=./certs/demo-front.local-key.pem \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "TLS certificate files not found, skipping demo-front-tls"
fi

## demo-reader cert
if [[ -f ./certs/demo-reader.local.pem && -f ./certs/demo-reader.local-key.pem ]]; then
  kubectl create secret tls demo-reader-tls \
    -n demo-front \
    --cert=./certs/demo-reader.local.pem \
    --key=./certs/demo-reader.local-key.pem \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "TLS certificate files not found, skipping demo-reader-tls"
fi

# Run job to create and grant permissions db users: demo-back and demo-reader
kubectl delete job postgres-create-app-users -n postgres --ignore-not-found
kubectl apply -f job-create-db-users.yaml
sleep 5

# 1. Deploy Back-App
helm upgrade --install back-app ./app-chart \
  --version $VERSION \
  --namespace demo-back \
  --create-namespace \
  -f ./app-deployment-values/values-back.yaml

# 2. Deploy Front-App
helm upgrade --install front-app ./app-chart \
  --version $VERSION \
  --namespace demo-front \
  --create-namespace \
  -f ./app-deployment-values/values-front.yaml

# 3. Deploy Reader-App
helm upgrade --install reader-app ./app-chart \
  --version $VERSION \
  --namespace demo-reader \
  --create-namespace \
  -f ./app-deployment-values/values-reader.yaml

# We dont have a dns server on ks8 cluster, so add Dns records to the local hosts file.
# Check if we have 1 node, otherwise please update /etc/hosts
# Ex:
# 172.17.19.117 demo-front.local
# 172.17.19.117 demo-reader.local
HOSTS="demo-front.local demo-reader.local"
NODES=$(kubectl get nodes --no-headers | wc -l)
if [ "$NODES" -eq 1 ]; then
  IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

  for HOST in $HOSTS; do
    sudo sed -i "/[[:space:]]$HOST$/d" /etc/hosts
    echo "$IP $HOST" | sudo tee -a /etc/hosts >/dev/null
  done
else
  echo "Expected 1 k3s node, found $NODES. Skipping /etc/hosts."
fi
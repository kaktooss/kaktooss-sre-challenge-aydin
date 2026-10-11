#!/bin/bash
set -e # Exit immediately if a build step fails

echo "=========================================="
echo " Add Helm Repositories"
echo "=========================================="

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

echo "=========================================="
echo " Deploy Kafka"
echo "=========================================="

helm upgrade --install kafka bitnami/kafka \
  --version 32.4.3 \
  --namespace kafka \
  --create-namespace \
  -f ./app-deployment-values/values-kafka.yaml

echo "=========================================="
echo " Deploy Postgre"
echo "=========================================="
# Create postgresql database db password
kubectl create ns postgres --dry-run=client -o yaml | kubectl apply -f -

#psotgresdb
kubectl create secret generic postgres-auth \
  --namespace postgres \
  --from-literal=postgres-password='93acci4yRWVe' \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy Postgresql
helm upgrade --install postgres bitnami/postgresql \
  --version 18.12.4 \
  --namespace postgres \
  --create-namespace \
  --set image.registry=docker.io \
  --set image.repository=bitnamilegacy/postgresql \
  --set image.tag=17.6.0-debian-12-r4 \
  --set global.security.allowInsecureImages=true \
  --set auth.existingSecret="postgres-auth" \
  --set auth.secretKeys.adminPasswordKey="postgres-password" \
  --set auth.database="postgres"

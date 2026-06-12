#!/bin/bash

set -e

CLUSTER_NAME="vote-test-cluster"

echo "Checking Kind cluster..."

if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
echo "Creating Kind cluster..."
kind create cluster 
--name ${CLUSTER_NAME} 
--config .github/kind-config.yaml
else
echo "Kind cluster already exists."
fi

echo "Installing NGINX Ingress Controller..."

kubectl apply -f 
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait 
--namespace ingress-nginx 
--for=condition=ready pod 
--selector=app.kubernetes.io/component=controller 
--timeout=180s

echo "Deploying manifests..."

kubectl apply -f k8s-specifications/

echo "Waiting for workloads..."

kubectl rollout status deployment/redis
kubectl rollout status deployment/vote
kubectl rollout status deployment/result
kubectl rollout status deployment/worker
kubectl rollout status statefulset/db

echo "Deployment completed successfully."
#!/bin/bash

set -e

echo "Deploying manifests..."

kubectl apply -f k8s-specifications/

echo "Waiting for workloads..."

kubectl rollout status deployment/redis
kubectl rollout status deployment/vote
kubectl rollout status deployment/result
kubectl rollout status deployment/worker
kubectl rollout status statefulset/db

echo "Deployment completed successfully."


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


# Example Voting App – Kubernetes Deployment with CI/CD

## Overview

This project deploys the Docker Example Voting Application on Kubernetes with production-oriented improvements including:

* Kubernetes Deployments
* PostgreSQL StatefulSet
* Persistent Volume Claims (PVC)
* Kubernetes Secrets
* Resource Requests and Limits
* Health Checks (Liveness & Readiness Probes)
* NGINX Ingress
* GitHub Actions CI/CD Pipeline
* Docker Image Build & Push
* Automated Integration Testing using Kind
* Smoke Testing
* Single-command Bootstrap Deployment

---

## Architecture

Application Components:

* Vote Service (Frontend)
* Redis Queue
* Worker Service
* PostgreSQL Database
* Result Service (Frontend)

Workflow:

```text
User
  │
  ▼
Vote Service
  │
  ▼
Redis
  │
  ▼
Worker
  │
  ▼
PostgreSQL
  │
  ▼
Result Service
```

---

## Kubernetes Resources

### Deployments

* vote
* result
* redis
* worker

### StatefulSet

* db (PostgreSQL)

### Services

* vote
* result
* redis
* db

### Storage

* Persistent Volume Claim (PVC)
* Persistent Database Storage

### Secrets

* Database Credentials stored in Kubernetes Secret

### Ingress

Hosts:

* vote.local
* result.local

---

## Resource Management

All workloads use resource requests and limits.

Example:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 250m
    memory: 256Mi
```

---

## Health Checks

Liveness and readiness probes are configured for application services where supported by the container image.

Examples include:

* Vote Service
* Result Service
* Redis
* PostgreSQL

---

## CI/CD Pipeline

GitHub Actions workflow performs:

### 1. Linting

* flake8
* yamllint
* kubeconform

### 2. Build

* Docker image build
* Docker image push to Docker Hub

### 3. Integration Testing

Creates a Kind cluster and:

* Deploys Kubernetes manifests
* Waits for workloads
* Deploys Ingress Controller
* Executes smoke tests

### 4. Smoke Testing

Validates:

* Vote service accessibility
* HTTP 200 response
* Valid application content

---

## Prerequisites

Install:

* Docker
* kubectl
* Kind
* Git

---

## Local Deployment

### Clone Repository

```bash
git clone https://github.com/shaan-777/example-voting-app.git
cd example-voting-app
```

### Configure Hosts

Add the following entry:

```text
127.0.0.1 vote.local result.local
```

Mac/Linux:

```bash
sudo nano /etc/hosts
```

---

## Deploy Application

Single command deployment:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This script:

* Applies all manifests
* Waits for deployments
* Verifies rollout completion

---

## Verify Deployment

```bash
kubectl get pods
```

```bash
kubectl get svc
```

```bash
kubectl get ingress
```

---

## Access Application

Vote Application:

```text
http://vote.local
```

Results Application:

```text
http://result.local
```

---

## Database Verification

List tables:

```bash
kubectl exec -it db-0 -- psql -U postgres -c "\dt"
```

---

## Useful Commands

View Pods:

```bash
kubectl get pods
```

View Logs:

```bash
kubectl logs deployment/vote

kubectl logs deployment/result

kubectl logs deployment/worker
```

Follow Worker Logs:

```bash
kubectl logs deployment/worker -f
```

Check Ingress:

```bash
kubectl describe ingress voting-app-ingress
```

---

## CI/CD Validation

View workflow runs:

```bash
gh run list --repo shaan-777/example-voting-app
```

---

## Project Features Completed

* Kubernetes Deployments
* PostgreSQL StatefulSet
* Persistent Storage
* Kubernetes Secrets
* Resource Limits
* Health Checks
* Ingress Routing
* Docker Image Build
* GitHub Actions CI/CD
* Kind Integration Testing
* Smoke Testing
* Bootstrap Deployment Script

---

## Author

Krith Thakker

GitHub:
https://github.com/shaan-777
# Example Voting App

A simple distributed application running across multiple Docker containers.

## Getting started

Download [Docker Desktop](https://www.docker.com/products/docker-desktop) for Mac or Windows. [Docker Compose](https://docs.docker.com/compose) will be automatically installed. On Linux, make sure you have the latest version of [Compose](https://docs.docker.com/compose/install/).

This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

Run in this directory to build and run the app:

```shell
docker compose up
```

The `vote` app will be running at [http://localhost:8080](http://localhost:8080), and the `results` will be at [http://localhost:8081](http://localhost:8081).

Alternately, if you want to run it on a [Docker Swarm](https://docs.docker.com/engine/swarm/), first make sure you have a swarm. If you don't, run:

```shell
docker swarm init
```

Once you have your swarm, in this directory run:

```shell
docker stack deploy --compose-file docker-stack.yml vote
```

## Run the app in Kubernetes

The folder k8s-specifications contains the YAML specifications of the Voting App's services.

Run the following command to create the deployments and services. Note it will create these resources in your current namespace (`default` if you haven't changed it.)

```shell
kubectl create -f k8s-specifications/
```

The `vote` web app is then available on port 31000 on each host of the cluster, the `result` web app is available on port 31001.

To remove them, run:

```shell
kubectl delete -f k8s-specifications/
```

## Architecture

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.

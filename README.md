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

This is based on the [Docker Example Voting App](https://github.com/dockersamples/example-voting-app) — a simple distributed app with a Python (Flask) vote frontend, a Redis queue, a .NET worker, a Postgres database, and a Node.js result frontend. The original app only accepts one vote per client browser and is intentionally simple — it's a demo of how these pieces (queues, persistent data, multiple languages) fit together in containers, now extended for Kubernetes.

---

## Architecture

![Architecture diagram](architecture.excalidraw.png)

Application Components:

* Vote Service (Frontend, Python/Flask)
* Redis Queue
* Worker Service (.NET)
* PostgreSQL Database
* Result Service (Frontend, Node.js)

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

## What Changed and Why

The original manifests were enhanced with the following production-oriented improvements:

* **Migrated PostgreSQL to a StatefulSet** with a PersistentVolumeClaim — ensures stable network identity and that vote data survives pod restarts/rescheduling, instead of using `emptyDir` (which is wiped on pod recreation).
* **Added a Kubernetes Secret (`db-credentials`)** for Postgres username/password/db name — removed plaintext credentials from the deployment YAML.
* **Added resource requests and limits** on every workload (vote, result, redis, worker, db) — prevents any one pod from starving others on the node.
* **Added readiness and liveness probes** on every workload where the container image supports it (HTTP probes for vote/result, TCP probe for redis, `pg_isready` exec probe for Postgres).
* **Replaced NodePort with NGINX Ingress** for `vote` and `result` — host-based routing (`vote.local`, `result.local`) instead of fixed high-numbered ports, closer to how a real cluster would expose services.
* **Built a GitHub Actions CI/CD pipeline** scoped to the `vote` service: lint → build & push to Docker Hub → spin up an ephemeral Kind cluster → deploy → install ingress-nginx → smoke test via Ingress.
* **Added a bootstrap script** (`bootstrap.sh`) for one-command local deployment.

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
* db (headless, for the StatefulSet)

### Storage
* PersistentVolumeClaim for PostgreSQL data (via `volumeClaimTemplates`)

### Secrets
* `db-credentials` — Postgres username, password, and database name

### Ingress
Hosts:
* `vote.local` → vote service
* `result.local` → result service

---

## Resource Management

All workloads define resource requests and limits. Example:

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

Liveness and readiness probes are configured for every workload, using the most appropriate probe type for each:

* **Vote / Result** — HTTP `GET /` probes
* **Redis** — TCP socket probe on port 6379
* **PostgreSQL** — `pg_isready` exec probe
* **Worker** — process-presence exec probe for liveness (see Trade-offs — the worker image has no HTTP/TCP health endpoint)

---

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/vote-ci.yml`), triggered on changes to `vote/**`, `k8s-specifications/**`, or the workflow file itself:

### 1. Lint
* `flake8` on `vote/app.py`
* `yamllint` on `k8s-specifications/`
* `kubeconform` for K8s manifest schema validation

### 2. Build & Push
* Builds the vote Docker image
* Pushes to Docker Hub, tagged with both `latest` and the commit SHA

### 3. Integration Test (on Kind)
* Spins up a fresh Kind cluster with port mappings to the host
* Patches the vote deployment to use the freshly-built image
* Applies all manifests
* Installs the NGINX Ingress Controller and waits for it to be ready
* Waits for redis and vote rollouts (required); result/worker are best-effort

### 4. Smoke Test
* Sends a request through the Ingress (`Host: vote.local`) to the mapped local port
* Verifies HTTP 200 and that the response contains real vote page content (`Cats`/`Dogs`/`Vote`/`Option`)
* On failure, dumps pod status, ingress status, ingress-controller logs, vote pod logs, and recent events for debugging

---

## Prerequisites

Install:
* Docker
* kubectl
* Kind
* Git

---

## Local Deployment

<img width="1331" height="841" alt="Screenshot 2026-06-12 at 17 31 08" src="https://github.com/user-attachments/assets/46bdbbc7-1fc7-4e1f-947b-580984bac378" />
<img width="1299" height="808" alt="Screenshot 2026-06-12 at 17 31 00" src="https://github.com/user-attachments/assets/0676976e-d114-4fb1-821d-1085217a210c" />
<img width="1279" height="811" alt="Screenshot 2026-06-12 at 17 30 49" src="https://github.com/user-attachments/assets/b3ab1fc7-276b-40e6-abdb-a2ffc8e77056" />
<img width="1330" height="785" alt="Screenshot 2026-06-12 at 17 30 36" src="https://github.com/user-attachments/assets/ef2c3aff-1989-4ebc-ab5f-1b13f3fd056d" />


### 1. Clone Repository

```bash
git clone https://github.com/shaan-777/example-voting-app.git
cd example-voting-app
```

### 2. Configure Hosts

Add the following entry to your hosts file:

```text
127.0.0.1 vote.local result.local
```

Mac/Linux:

```bash
sudo nano /etc/hosts
```

### 3. Deploy

Single command deployment:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This script:
* Creates/uses a local Kind cluster (named `vote-test-cluster`)
* Installs the NGINX Ingress Controller
* Applies all manifests
* Waits for all deployments and the StatefulSet to roll out

### 4. Verify Deployment

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl get statefulset
kubectl get pvc
kubectl get secret
```

### 5. Access the Application

* Vote app: http://vote.local:8080
* Results app: http://result.local:8080

> Note: port `8080`/`8443` (instead of the default `80`/`443`) is used for the Kind cluster's host port mappings, since Docker Desktop on macOS often binds port 80 for its own internal proxy. If port 80 is free on your machine, you can change `hostPort` back to `80`/`443` in `.github/kind-config.yaml` and drop the `:8080` from the URLs above.

Cast a vote in the vote app, then refresh the result app — your vote should appear within a few seconds.

### Database Verification

List tables:

```bash
kubectl exec -it db-0 -- psql -U postgres -c "\dt"
```

---

## Useful Commands

View pods:
```bash
kubectl get pods
```

View logs:
```bash
kubectl logs deployment/vote
kubectl logs deployment/result
kubectl logs deployment/worker
```

Follow worker logs:
```bash
kubectl logs deployment/worker -f
```

Check ingress:
```bash
kubectl describe ingress voting-app-ingress
```

---

## CI/CD Validation

<img width="1469" height="468" alt="Screenshot 2026-06-12 at 17 29 35" src="https://github.com/user-attachments/assets/b73bbec4-de57-4885-981f-a7aa3a557f6b" />


<img width="1470" height="597" alt="Screenshot 2026-06-12 at 17 39 36" src="https://github.com/user-attachments/assets/1ba619a5-1ca9-48ba-b316-a3ce98447046" />


View workflow runs:

```bash
gh run list --repo shaan-777/example-voting-app
```

---

## Troubleshooting

### Pods are not starting

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Common causes: image pull errors, resource limits too low for the node, or a failing readiness/liveness probe causing repeated restarts. Check `kubectl describe pod` events and `kubectl logs <pod-name>`.

### A vote doesn't reach the result app

This usually means one of the links in the chain (vote → redis → worker → db → result) is broken.

1. Check redis is up and the vote pod can reach it: `kubectl logs deployment/vote`
2. Check the worker is consuming votes: `kubectl logs deployment/worker -f` — it should print a row insert on each new vote.
3. Check Postgres is reachable and has data: `kubectl exec -it db-0 -- psql -U postgres -c "select * from votes;"`
4. If the worker pod is stuck `CrashLoopBackOff`, it's likely Postgres wasn't ready yet when the worker started — the worker has no retry/backoff logic in the original image, so restarting the worker pod (`kubectl delete pod -l app=worker`) after `db-0` is ready usually fixes it.

### Ingress not accessible / 404 or connection refused on vote.local

```bash
kubectl get ingress
kubectl describe ingress voting-app-ingress
kubectl get pods -n ingress-nginx
```

* Confirm `/etc/hosts` has `127.0.0.1 vote.local result.local`.
* Confirm the ingress-nginx controller pod is `Running` and `Ready` — it can take 30-60s after install for the admission webhook to register, during which routing requests may briefly fail.
* Confirm `kubectl get ingress -o wide` shows an address and that the `vote`/`result` services are listed as backends.
* Confirm you're using the correct port in the URL (`:8080`/`:8443` if using the default config in this repo).

### Port 80/443 already in use when creating the Kind cluster

```
Bind for 0.0.0.0:80 failed: port is already allocated
```

This means something on your machine (often Docker Desktop's own proxy on macOS) is already using port 80. Either stop that process, or use the `8080`/`8443` host port mapping already configured in `.github/kind-config.yaml` (and access the app via `:8080` as shown above).

---

## Trade-offs

* **Kind** was used for local/CI Kubernetes instead of a managed cloud cluster — keeps everything free and runnable on a laptop or GitHub-hosted runner, at the cost of not testing cloud-specific networking/storage.
* **Docker Hub** was used as the container registry for simplicity over GHCR.
* Deployment uses a lightweight **bootstrap script** rather than Helm/Kustomize — faster to get working end-to-end, but less reusable across environments (no separate dev/staging values).
* **Host ports 8080/8443** are used instead of 80/443 for the Kind cluster, to avoid a common conflict with Docker Desktop's internal proxy on macOS.
* The **worker** has no HTTP/TCP health endpoint in the upstream image, so its liveness probe is a basic process-presence check rather than a true application health check — a custom worker image with a `/healthz` endpoint would be more reliable.
* **Redis** uses `emptyDir` storage (acceptable since it's just a queue, not a system of record) rather than a PVC.
* With more time: add Network Policies (only vote→redis, only worker→db), a HorizontalPodAutoscaler on vote, and a Helm chart with per-environment values files.

---

## Video Walkthrough

Video Link: https://www.loom.com/share/2102ea099a1a494b9812ae2e9e996ad3

---

## Author

Krith Thakker

GitHub: https://github.com/shaan-777

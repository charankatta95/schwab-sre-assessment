# Schwab SRE Take-Home Assessment

A two-application platform on GKE Autopilot with multi-environment isolation, full observability (Cloud Logging → BigQuery → Grafana), keyless service-to-service authentication (Workload Identity + Secret Manager), and Terraform-managed cloud infrastructure — built against a GCP free-trial account, with every free-tier-driven scope decision explicitly documented rather than silently taken.

## Start here

| Document | What it covers |
|---|---|
| [`docs/architecture.md`](docs/architecture.md) | Full system diagram and component-by-component breakdown of what was actually built |
| [`docs/design-decisions.md`](docs/design-decisions.md) | Every trade-off made and why (one cluster vs. two, managed vs. in-cluster data services, security implementation depth, Terraform coverage, etc.) |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | Six real incidents hit during the build, each with symptom → investigation → root cause → fix |

## Architecture at a glance

- **1 GKE Autopilot cluster** (`schwab-cluster`, `us-central1`), with **2 namespaces** (`app-primary`, `app-secondary`) simulating two isolated environments, each with its own `ResourceQuota`
- **2 applications** (`web-app-a`, `web-app-b`), each 3 replicas with HPA (2-6, 60% CPU), deployed identically into both namespaces
- `web-app-b` backed by in-cluster **Postgres** (StatefulSet) and **Redis** (Deployment)
- **GKE-managed Ingress** → real Global External HTTP(S) Load Balancer, routing `/app-a` and `/app-b`
- **Observability**: Cloud Logging → BigQuery export sink (`gke_logs` dataset) → Grafana Cloud dashboard (4 panels: error rate, pod/controller lifecycle events, CPU by namespace, memory by namespace)
- **Security**: Workload Identity (keyless GCP API auth from pods) and Secret Manager (keyless secret retrieval), both implemented and verified live; Binary Authorization designed but not built (see design decisions)
- **IaC**: Terraform for VPC/networking, the GKE cluster, and project-level IAM service accounts

Full detail: [`docs/architecture.md`](docs/architecture.md).

## Repository structure

```
schwab-sre-assessment/
├── README.md                      (this file)
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── network.tf                 (VPC, subnet, Cloud Router, Cloud NAT)
│   ├── firewall.tf
│   ├── gke.tf                     (Autopilot cluster)
│   └── iam.tf                     (ci_cd / sre / ops / dev service accounts)
├── k8s/
│   ├── rbac/
│   │   └── dev-namespace-role.yaml
│   ├── namespace-quota-primary.yaml
│   ├── namespace-quota-secondary.yaml
│   ├── app-a/
│   │   └── deployment.yaml        (Deployment + Service + HPA)
│   ├── app-b/
│   │   ├── postgres.yaml          (StatefulSet + Service)
│   │   ├── redis.yaml             (Deployment + Service)
│   │   └── deployment.yaml        (Deployment + Service + HPA)
│   └── ingress.yaml
└── docs/
    ├── architecture.md
    ├── design-decisions.md
    ├── troubleshooting.md
    ├── bigquery-schema.md
    ├── bigquery-queries.sql
    ├── grafana-dashboard.json
    └── grafana-dashboard.jpg
```

**Not in this repository, by design**: `grafana-reader-sa-key.json` — the JSON key used to connect Grafana Cloud's BigQuery data source. This is a live credential and is intentionally excluded (add it to `.gitignore` before committing if you haven't already: `echo "*-sa-key.json" >> .gitignore`).

## Prerequisites

- A GCP project with billing enabled (this was built against a new-account $300/90-day free trial)
- `gcloud`, `kubectl`, `terraform`, and `bq` CLIs (all pre-installed in Google Cloud Shell)
- APIs enabled: Kubernetes Engine, Cloud Resource Manager, Cloud Logging, BigQuery, Secret Manager, IAM (`gcloud services enable container.googleapis.com cloudresourcemanager.googleapis.com bigquery.googleapis.com secretmanager.googleapis.com`)

## Deploy from scratch

```bash
# 1. Cloud infrastructure
cd terraform
terraform init
terraform apply

# 2. Cluster credentials
gcloud container clusters get-credentials schwab-cluster --region us-central1 --project <your-project-id>

# 3. Namespaces, quotas, RBAC
kubectl apply -f ../k8s/rbac/dev-namespace-role.yaml
kubectl apply -f ../k8s/namespace-quota-primary.yaml
kubectl apply -f ../k8s/namespace-quota-secondary.yaml

# 4. Application workloads — repeat for both namespaces (app-primary, app-secondary)
#    (create the per-namespace ConfigMaps/Secrets referenced in each deployment.yaml first)
kubectl apply -f ../k8s/app-a/deployment.yaml -n app-primary
kubectl apply -f ../k8s/app-b/postgres.yaml -n app-primary
kubectl apply -f ../k8s/app-b/redis.yaml -n app-primary
kubectl apply -f ../k8s/app-b/deployment.yaml -n app-primary
# ...repeat the four commands above with -n app-secondary

# 5. Ingress (provisioning the real load balancer takes 5-15 minutes)
kubectl apply -f ../k8s/ingress.yaml
kubectl get ingress -n app-primary -w
```

Observability (BigQuery sink, Grafana dashboard) and security (Workload Identity, Secret Manager) resources were provisioned imperatively via `gcloud` during this build rather than through Terraform — see [`docs/design-decisions.md`](docs/design-decisions.md) §7 for the reasoning and the exact commands used, which can be re-run against a fresh project.

## Verify it's working

```bash
# Apps reachable through the real load balancer
curl http://<ingress-address>/app-a
curl http://<ingress-address>/app-b

# RBAC boundary holds
kubectl auth can-i create deployments --as=system:serviceaccount:dev:dev-sa -n dev        # yes
kubectl auth can-i create deployments --as=system:serviceaccount:dev:dev-sa -n app-primary # no

# Logs are flowing into BigQuery
bq query --use_legacy_sql=false < docs/query1-error-rate.sql
bq query --use_legacy_sql=false < docs/query2-pod-restarts.sql

# Workload Identity: keyless GCP API access from a pod
kubectl run wi-check --rm -it -n app-primary --image=google/cloud-sdk:slim \
  --overrides='{"spec": {"serviceAccount": "wi-demo-ksa"}}' -- gcloud auth list
```

The Grafana dashboard ("Schwab SRE Assessment Dashboard") is on Grafana Cloud's free tier under this account; a static snapshot is included at `docs/grafana-dashboard.jpg` and the full definition at `docs/grafana-dashboard.json`.

## Known limitations

Everything below is a deliberate, documented scope decision (not an oversight) — full reasoning for each is in [`docs/design-decisions.md`](docs/design-decisions.md):

- One cluster with two namespaces, not two physical clusters
- In-cluster Postgres/Redis, not Cloud SQL/Memorystore
- Both apps run a stock demo image (`hello-app`), not custom application code
- A fourth dashboard panel (request latency percentiles) was scoped out — load-balancer access logging was never enabled
- Secret Manager: implemented and verified for keyless retrieval; the live Postgres StatefulSet still reads its password from a Kubernetes Secret (CSI-driver migration documented, not executed)
- Binary Authorization: designed, not implemented
- Some cloud resources (BigQuery sink, two service accounts, one Secret Manager secret) are not yet Terraform-managed

## Cost controls and teardown

A $50 GCP Billing Budget is configured on this project with alerts at 50/90/100%. The environment is intentionally left running past the build's completion so the live dashboard and endpoints remain available for review; teardown when no longer needed:

```bash
cd terraform
terraform destroy

# Resources created outside Terraform:
bq rm -r -f schwab-sre-assessment:gke_logs
gcloud logging sinks delete <sink-name> --project=schwab-sre-assessment
gcloud iam service-accounts delete workload-identity-demo@schwab-sre-assessment.iam.gserviceaccount.com --quiet
gcloud secrets delete postgres-password --project=schwab-sre-assessment --quiet
```

# Architecture — Schwab SRE Take-Home Assessment

## 1. Overview

This environment implements the requested architecture — two applications running on GKE with full observability, RBAC-based access control, keyless service-to-service authentication, and infrastructure-as-code — on a single GCP project (`schwab-sre-assessment`) provisioned under a new-account $300/90-day free trial. Where the original spec assumed unrestricted budget (e.g., a second physical cluster, a fully-implemented Binary Authorization policy, load-balancer request-log-based latency panels), a deliberate, documented scope decision was made instead. Every such decision is called out explicitly below and expanded on in `design-decisions.md`.

## 2. High-level diagram

```
                                   Internet
                                      |
                                      v
                    +-----------------------------------+
                    |  GCE Global External HTTP(S) LB    |
                    |  (auto-provisioned by GKE Ingress) |
                    +-----------------+-------------------+
                                      |
                        schwab-ingress (host: yourapp.example.com)
                         /app-a  -->  web-app-a:80
                         /app-b  -->  web-app-b:80
                                      |
   +----------------------------------------------------------------+
   |                 GKE Autopilot Cluster: schwab-cluster           |
   |                       (region: us-central1)                    |
   |                                                                 |
   |   +-------------------------+   +-------------------------+    |
   |   |   Namespace: app-primary |   |  Namespace: app-secondary|   |
   |   |  (simulates "cluster 1") |   |  (simulates "cluster 2") |   |
   |   |                          |   |                          |   |
   |   |  web-app-a (3 replicas,  |   |  web-app-a (3 replicas,  |   |
   |   |    HPA 2-6, cpu 60%)     |   |    HPA 2-6, cpu 60%)     |   |
   |   |  web-app-b (3 replicas,  |   |  web-app-b (3 replicas,  |   |
   |   |    HPA 2-6, cpu 60%)     |   |    HPA 2-6, cpu 60%)     |   |
   |   |  postgres-0 (StatefulSet)|   |  postgres-0 (StatefulSet)|   |
   |   |  redis (Deployment)      |   |  redis (Deployment)      |   |
   |   |  ResourceQuota: env-quota|   |  ResourceQuota: env-quota|   |
   |   |    (cpu:2, mem:4Gi,      |   |    (cpu:2, mem:4Gi,      |   |
   |   |     pods:20)             |   |     pods:20)             |   |
   |   +-------------------------+   +-------------------------+    |
   |                                                                 |
   |   +-------------------------+                                  |
   |   |   Namespace: dev         |   RBAC demo: Role +              |
   |   |   Role: dev-namespace-   |   RoleBinding scoping a          |
   |   |     admin (namespace-    |   project-level IAM identity     |
   |   |     scoped only)         |   down to one namespace          |
   |   +-------------------------+                                  |
   +----------------------------------------------------------------+
                    |                                  |
                    v                                  v
        +--------------------------+     +---------------------------+
        |     Cloud Logging         |     |   Workload Identity pool   |
        |  (stdout/stderr/events/   |     |  schwab-sre-assessment.    |
        |   cloudaudit/etc.)        |     |    svc.id.goog             |
        +-------------+--------------+     +---------------+-------------+
                      |                                    |
                      v                                    v
        +--------------------------+     +---------------------------+
        |  BigQuery export sink    |     |  workload-identity-demo-SA  |
        |  dataset: gke_logs       |     |  (bigquery.dataViewer,      |
        |  (stdout_*, stderr_*,    |     |   secretmanager.            |
        |   events_*, cloudaudit_*,|     |   secretAccessor)           |
        |   GCEGuestAgent_*, ...)  |     +---------------------------+
        +-------------+--------------+                    |
                      |                                    v
                      v                        +---------------------------+
        +--------------------------+           |  Secret Manager             |
        |   Grafana Cloud           |           |  secret: postgres-password  |
        |   (free tier)             |           +---------------------------+
        |  - BigQuery data source   |
        |  - Cloud Monitoring       |
        |    (stackdriver) source   |
        |                           |
        |  Dashboard: "Schwab SRE   |
        |   Assessment Dashboard"   |
        |  - Application Error Rate |
        |  - Pod & Controller       |
        |    Lifecycle Events       |
        |  - CPU Utilization by ns  |
        |  - Memory Utilization     |
        |    by ns                  |
        +--------------------------+
```

## 3. Cluster topology and the "two clusters" decision

The spec called for two GKE clusters. This build uses **one GKE Autopilot cluster (`schwab-cluster`, region `us-central1`) with two application namespaces (`app-primary`, `app-secondary`)** that each carry a full, independent copy of the application stack (both web apps, their own Postgres and Redis, their own `ResourceQuota`). This was a deliberate decision, not a shortcut taken silently — reasoning is in `design-decisions.md`, but the summary is: a second real cluster roughly doubles Autopilot's baseline compute cost for no architectural learning benefit in a free-tier/trial context, whereas namespace isolation exercises the same RBAC, quota, and multi-environment patterns a second cluster would.

Each namespace enforces its own `ResourceQuota` (2 CPU / 4Gi memory / 20 pods), independent of the other — so `app-primary` and `app-secondary` cannot starve each other's resources, which is the property a second cluster would also provide, just without a second control plane's overhead.

## 4. RBAC and IAM boundary

- **Project-level IAM** (via Terraform, `iam.tf`): four service accounts — `ci_cd` (`roles/container.developer`), `sre` (`roles/monitoring.admin`), `ops` (`roles/logging.admin`), `dev` (`roles/container.clusterViewer`) — model the access a CI pipeline, an SRE, an operator, and a developer would each need at the GCP project level.
- **Namespace-level RBAC**: a `dev` namespace holds a `Role` (`dev-namespace-admin`) and `RoleBinding` that grants the `dev` service account full control *only within that namespace* — verified via `kubectl auth can-i` returning `yes` inside `dev` and `no` outside it. This demonstrates the pattern called out in the design decisions: **project IAM sets the outer boundary of what a principal can touch; Kubernetes RBAC takes over and narrows that further inside the cluster.** A principal with a broad GCP role is still constrained to specific namespaces by RBAC.

## 5. Application layer

- **web-app-a**: stateless, 3 replicas, HPA (2-6 replicas, 60% CPU target), its own `ConfigMap`/`Secret` per namespace (`app-a-config`, `app-a-secret`).
- **web-app-b**: same replica/HPA shape, additionally depends on in-namespace Postgres and Redis, with `DATABASE_URL`, `REDIS_URL`, `PUBSUB_TOPIC`, and `ENV` supplied via `app-b-config`/`app-b-secret`.
- Both apps run `gcr.io/google-samples/hello-app:2.0` — Google's standard minimal HTTP demo image. This is a deliberate, disclosed substitution for custom application code: the assessment's focus is the *platform* (deployment topology, scaling, secrets, observability, security), not a bespoke application, and `hello-app` gives real, working HTTP endpoints for the Ingress, HPA, and logging pipeline to operate against. One consequence, documented in the troubleshooting log: since `hello-app` logs everything to stderr regardless of real severity, the "error rate" BigQuery panel reflects that logging behavior rather than genuine application errors — called out honestly rather than presented as a real error signal.
- **Postgres** (StatefulSet) and **Redis** (Deployment) back `web-app-b` in each namespace, each with explicit resource requests (see Troubleshooting #1) and, for Postgres, a `PGDATA` subdirectory fix (Troubleshooting #2) to work around the ext4 `lost+found` issue on PVC-backed storage.

## 6. Networking and ingress

A GKE-managed `Ingress` (`schwab-ingress`, deployed in `app-primary`) provisions a real **Global External HTTP(S) Load Balancer** — backend services, network endpoint groups (NEGs), URL map, target HTTP proxy, and forwarding rule, all auto-created by GKE. Routing:
- `/app-a` → `web-app-a` Service, port 80
- `/app-b` → `web-app-b` Service, port 80

Live address: `136.81.59.10`, host `yourapp.example.com` (not a real DNS record — the assessment doesn't require public DNS, so this is used as a routing/host-header convention only, verified via direct `curl` against the LB IP). VPC networking (`network.tf`, `firewall.tf`) and Cloud NAT/Router are provisioned via Terraform for the Autopilot cluster's node connectivity.

## 7. Observability pipeline

**Path**: application/system logs → Cloud Logging (automatic on GKE) → a Cloud Logging **export sink** → **BigQuery** dataset `gke_logs` → **Grafana Cloud** (free tier), queried via two different data sources depending on data type.

- **Log-derived data** (error rates, Kubernetes lifecycle events) is queried from BigQuery using raw SQL against the exported tables — `stderr_*`/`stdout_*` for the error-rate panel, `events_*` for the pod/controller lifecycle panel. (See `docs/bigquery-queries.sql` for both final queries, and `docs/bigquery-schema.md` for the real captured schemas.)
- **Resource-utilization data** (CPU, memory) is **not** available from log exports — it's queried directly from Google Cloud Monitoring via Grafana's Cloud Monitoring (`stackdriver`) data source, using the container-scoped metrics `kubernetes.io/container/cpu/core_usage_time` and `kubernetes.io/container/memory/used_bytes`, grouped by `resource.label.namespace_name`.
- A planned fourth panel (p50/p95/p99 request latency from load-balancer access logs) was scoped out: GKE's auto-created Ingress backend services do not have HTTP(S) load-balancer access logging enabled by default (it requires an explicit `BackendConfig` opt-in), and no such logs were ever generated or exported. This is a disclosed scope decision, not an unnoticed gap — see `design-decisions.md`.

Sink and dataset resources here were provisioned via `gcloud`/console rather than Terraform, as a time-boxing decision — see `design-decisions.md` and the Terraform section below.

## 8. Security

- **Workload Identity** (Autopilot default, cannot be disabled): a dedicated Kubernetes ServiceAccount (`wi-demo-ksa`, in `app-primary`) is bound to a dedicated GCP service account (`workload-identity-demo@schwab-sre-assessment.iam.gserviceaccount.com`) via the standard `iam.workloadIdentityUser` + KSA-annotation pattern. Verified working end-to-end from inside a pod using that KSA: `gcloud auth list` shows the GSA active with no key file present anywhere in the container, and a direct BigQuery REST API call using a minted access token successfully lists the dataset's tables. This directly replaces the pattern the Grafana BigQuery reader (`grafana-reader-sa`) currently uses — a downloadable JSON key (`~/grafana-reader-sa-key.json`, explicitly **not** committed to this repository) — because Grafana Cloud runs outside the cluster and cannot participate in GKE's Workload Identity pool.
- **Secret Manager**: the Postgres password, originally stored only as a plain (base64-encoded, not encrypted-at-rest-by-Kubernetes-in-any-meaningful-sense) Kubernetes `Secret`, was additionally stored as a real Secret Manager secret (`postgres-password`). The same `workload-identity-demo` service account was granted `roles/secretmanager.secretAccessor` scoped to that one secret (not project-wide), and retrieval was verified keylessly from a pod using the same Workload Identity binding. The live Postgres StatefulSet still consumes its password via the original Kubernetes Secret — migrating the StatefulSet itself to mount from Secret Manager via the CSI driver was scoped out as a design decision (see `design-decisions.md`) to avoid risk to an already-healthy stateful workload late in the build.
- **Binary Authorization**: not implemented. A meaningful dry-run policy requires a real attestor (a Container Analysis Note plus a Cloud KMS signing key) — `REQUIRE_ATTESTATION` mode will not even apply without one. Given the time budget, this is documented as an intended design in `design-decisions.md` rather than built.

## 9. Infrastructure as Code

Terraform (`terraform/`) covers: VPC network, subnetwork, Cloud Router, Cloud NAT, firewall rules, the GKE Autopilot cluster itself (`deletion_protection = false` for easy teardown), and the four project-level IAM service accounts and their bindings.

Provisioned **outside** Terraform, imperatively via `gcloud`/`kubectl`, as a disclosed time-boxing decision rather than an oversight: the BigQuery dataset and Cloud Logging export sink, the `workload-identity-demo` service account and its bindings, the Secret Manager secret, and all Kubernetes-native resources (namespaces, deployments, services, RBAC objects, HPAs, ResourceQuotas) — the last category is intentionally **not** Terraform-managed even in the target design, since it's owned by `kubectl apply` against manifests in `k8s/`, a defensible split between "cloud infrastructure" (Terraform's job) and "cluster workloads" (kubectl/manifests' job) that many real organizations also draw.

## 10. Cost controls

A GCP Billing Budget (`$50`, scoped to `schwab-sre-assessment`, with email alerts at 50%/90%/100%) was configured as a safety net against the $300 trial credit. Full teardown procedure (`terraform destroy` plus cleanup of imperatively-created resources) is documented in `README.md` and is intended to run once this submission's review window has closed.

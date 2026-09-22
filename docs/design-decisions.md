# Design Decisions — Schwab SRE Take-Home Assessment

This document records the deliberate trade-offs made while building this environment. The recruiting email accompanying this assessment explicitly stated that GCP free-tier-unavailable features could be skipped; every decision below follows that guidance, and each one favors an honestly-scoped, verifiable implementation over a larger implementation that would have consumed trial credit or build time without adding proportional signal about SRE skill.

---

## 1. One GKE Autopilot cluster with two namespaces, instead of two clusters

**Context**: the spec calls for two GKE clusters.

**Decision**: a single GKE Autopilot cluster (`schwab-cluster`), with two application namespaces (`app-primary`, `app-secondary`) that each run a complete, independent copy of the application stack — separate Deployments, separate Postgres/Redis, separate `ResourceQuota`.

**Why**: a second Autopilot cluster roughly doubles baseline compute spend (each cluster carries its own minimum node footprint) for a trial-credit account, without exercising meaningfully different SRE skills than namespace-level isolation already does. Namespace-scoped `ResourceQuota` and RBAC (see #2) demonstrate the same "environments shouldn't interfere with or over-privilege each other" property that two clusters would, at a fraction of the cost. This was raised as an open question early in the build and resolved deliberately at that point, not left ambiguous.

**Trade-off accepted**: this does not exercise true multi-cluster concerns — cross-cluster networking, a service mesh, or a multi-cluster ingress/failover story. That's a real gap relative to the original spec's two-cluster ask, and is called out here rather than glossed over.

---

## 2. In-cluster Postgres/Redis, not Cloud SQL/Memorystore

**Context**: an early open question was whether to run stateful backing services in-cluster (as deployed) or swap them for managed equivalents (Cloud SQL for Postgres, Memorystore for Redis).

**Decision**: kept in-cluster (StatefulSet + Deployment), backed by GCE Persistent Disk-backed PVCs.

**Why**: Cloud SQL and Memorystore both have non-trivial standing hourly costs even at their smallest tier, and both would run continuously for the life of this environment (days, not minutes) — a materially different cost profile than the compute-only in-cluster approach, which scales down naturally when idle. Running them in-cluster also happens to be *more* representative of raw Kubernetes operational skill (StatefulSet lifecycle, PVC/PV mechanics, the `lost+found` issue documented in `troubleshooting.md`) than pointing an app at a managed service would have been — a managed database mostly removes the Kubernetes-specific problems an SRE assessment is likely trying to probe.

**Trade-off accepted**: in-cluster Postgres/Redis means this environment doesn't demonstrate patterns specific to managed data services — automated backups, read replicas, IAM database authentication, cross-zone failover for the database layer. In a production system handling real data, a managed service would very likely be the correct call; this decision is scoped to a short-lived assessment environment, not a recommendation for production architecture.

---

## 3. `hello-app` demo image instead of custom application code

**Context**: both `web-app-a` and `web-app-b` run `gcr.io/google-samples/hello-app:2.0`, Google's minimal HTTP demo image, rather than purpose-written application code.

**Decision**: kept the demo image, with real Kubernetes-native configuration (ConfigMaps, Secrets, environment variables referencing Postgres/Redis/Pub-Sub) layered around it even though the demo image doesn't consume most of that configuration.

**Why**: the assessment's architecture spec is about the *platform* — deployment topology, scaling behavior, secrets management, observability, security posture — not about product/application logic. `hello-app` provides real, working HTTP endpoints that genuinely exercise the Ingress, HPA, and logging pipeline, which is what those components need to be validated against.

**Trade-off accepted, disclosed rather than hidden**: this has one concrete, visible consequence documented in `troubleshooting.md` — `hello-app` logs every request to stderr regardless of real severity, so the BigQuery-derived "error rate" panel reflects logging behavior, not genuine application error conditions. Rather than engineer around this to make the panel look more realistic, it's called out directly as a known limitation of using a demo image, which is more useful to a reviewer than a panel that silently implies something false.

---

## 4. Grafana Cloud (free tier) + BigQuery instead of self-hosted Grafana/Prometheus

**Decision**: observability uses Cloud Logging → BigQuery export → Grafana Cloud's free tier (for log-derived metrics), plus Grafana's Cloud Monitoring data source directly (for CPU/memory resource metrics), rather than standing up Prometheus + a self-hosted Grafana instance inside the cluster.

**Why**: a self-hosted Prometheus/Grafana stack means more in-cluster compute (another set of Deployments plus persistent storage for metrics retention) competing with the same namespace `ResourceQuota` the application workloads run under, for a capability Grafana Cloud's free tier already provides externally at zero marginal compute cost to the cluster. This also more accurately reflects how many real organizations consume Grafana today — as a managed service — rather than defaulting to self-hosting by convention.

**Trade-off accepted**: Grafana Cloud's free tier has its own limits (data source connection count, query complexity constraints that pushed some BigQuery panels into raw-SQL/"Code" mode rather than the visual builder) — documented in practice throughout the build rather than hit unexpectedly.

---

## 5. Load-balancer latency panel (p50/p95/p99) scoped out

**Context**: the dashboard plan included a fourth panel for HTTP request latency percentiles, sourced from load-balancer access logs.

**Decision**: not built. The other three panels (error rate, pod/controller lifecycle events, CPU/memory utilization by namespace) were completed and verified with real data; the fourth was consciously dropped rather than forced.

**Why**: GKE's auto-created Ingress backend services do not have HTTP(S) load-balancer access logging enabled by default — it requires an explicit `BackendConfig` resource with logging enabled, attached to each Service. This was discovered only after confirming (via `bq ls`) that no request-log table had ever appeared in BigQuery — the sink itself was correctly configured; there was simply no log stream to export, since it had never been turned on. Enabling it retroactively, waiting for propagation, and then generating enough synthetic traffic to produce a meaningful percentile distribution was judged to cost more remaining build time than the panel was worth, especially with three other panels already fully working with real data.

**Trade-off accepted**: the dashboard is missing a latency view, which is a legitimate SRE signal in a real production system. This is disclosed explicitly rather than presented as "four panels" when only three exist with real backing data.

---

## 6. Security: Workload Identity implemented fully; Secret Manager implemented for retrieval only; Binary Authorization documented, not built

**Workload Identity** — implemented and verified end-to-end: a dedicated KSA/GSA pair, bound correctly, proven via a live debug pod retrieving a real GCP API result (BigQuery table list) with zero key files present. This directly demonstrates the pattern that should also replace the JSON-key-based auth Grafana's BigQuery reader currently uses (not swapped, since Grafana Cloud runs outside GKE and can't participate in the cluster's Workload Identity pool — see `architecture.md` §8).

**Secret Manager** — the Postgres password was migrated into a real Secret Manager secret, with access granted to the same Workload Identity-bound service account and verified via the same keyless-retrieval pattern. **Decision**: stopped short of migrating the live Postgres StatefulSet to mount that secret via the Secret Manager CSI driver. **Why**: doing so would touch a StatefulSet that was, by this point in the build, healthy and stable after the `lost+found` debugging episode — the CSI driver mount also requires enabling a cluster-level add-on and introduces a new moving part late in the build, for a security improvement (secret retrieval mechanics) that had already been fully proven via the debug-pod pattern. The production migration path — `SecretProviderClass` + CSI volume mount on the StatefulSet — is documented here as the intended next step rather than executed against a live, working database.

**Binary Authorization** — not implemented at all, only designed. A dry-run policy that produces any meaningful audit signal requires `REQUIRE_ATTESTATION` evaluation mode, which in turn requires a real attestor resource — a Container Analysis Note plus a Cloud KMS asymmetric signing key. This is a legitimate amount of additional infrastructure (and a small ongoing KMS cost) for a control whose primary value in this exercise would be demonstrating awareness of the pattern, which can be communicated just as precisely in writing: the intended policy would set `globalPolicyEvaluationMode: ENABLE`, a `defaultAdmissionRule` in `DRYRUN_AUDIT_LOG_ONLY` enforcement mode requiring attestation from a project attestor backed by a KMS key, applied at the cluster level via `--binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE`. Violations would be visible in Cloud Logging without blocking any deployment — the correct posture for introducing this control gradually in a real environment.

---

## 7. Terraform coverage: cloud infrastructure fully codified, cluster workloads and a few auxiliary resources are not

**Decision**: Terraform (`terraform/`) owns VPC networking, the GKE Autopilot cluster, and the four project-level IAM service accounts + bindings. It does **not** own: the BigQuery dataset/Cloud Logging export sink, the Workload Identity demo service account, the Secret Manager secret, or any Kubernetes-native object (namespaces, Deployments, Services, RBAC, HPAs, ResourceQuotas — all owned by `kubectl apply` against manifests in `k8s/`).

**Why**: the Kubernetes-object split is intentional at the architecture level, not a time-boxing shortcut — many real organizations draw exactly this line, using Terraform for cloud provider resources and a separate tool (`kubectl`, Helm, Argo CD, etc.) for in-cluster object lifecycle, since the two have different change cadences and blast radii. The BigQuery/sink/demo-SA/secret gap **is** a time-boxing decision: these were built imperatively while iterating quickly on the observability and security sections, and reconciling them into Terraform state via `terraform import` after the fact was judged lower-value than finishing the working system with real, verified data. In a production rollout, these would be Terraform-managed like the rest of the cloud-layer resources.

---

## 8. Cost posture throughout

A $50 GCP Billing Budget with email alerts at 50/90/100% was configured against the project, scoped narrowly to `schwab-sre-assessment`, as a safety net against the $300/90-day trial credit — not because $50 was expected to be approached, but because an unattended budget-alert-free environment is itself a minor operational risk an SRE should default against. Full teardown (`terraform destroy` plus manual cleanup of the imperatively-created resources listed in §7) is intentionally deferred until after this submission's review window closes, so the live environment — including the Grafana dashboard and the LB endpoint — remains available for a walkthrough or interview discussion if useful.

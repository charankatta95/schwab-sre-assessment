# Troubleshooting Log — Schwab SRE Take-Home Assessment

This document records real incidents encountered while building this environment, each with the observed symptom, the investigation steps taken, the confirmed root cause, the fix applied, and what it demonstrates. Every incident below actually occurred during the build — nothing here is hypothetical.

---

## 1. Redis pods stuck at 0/1 with zero pods created (ResourceQuota vs. Autopilot defaults)

**Symptom**
After applying `redis.yaml`, `kubectl get pods,svc -n app-primary -l app=redis` returned `No resources found` — not a crashing pod, but *no pod at all* had been scheduled. The Deployment showed `0/1` ready with no ReplicaSet-created pods visible.

**Investigation**
`kubectl describe deployment redis -n app-primary` and `kubectl describe replicaset` showed events indicating pod creation was being rejected. Cross-checking against the namespace's `ResourceQuota` (`env-quota`: cpu 2, memory 4Gi, pods 20) revealed the quota was being exceeded even though Redis alone should have fit comfortably.

**Root cause**
GKE Autopilot auto-injects default resource requests (`cpu: 500m`, `memory: 2Gi`) into any container that doesn't explicitly declare its own `resources` block. Both the Postgres and Redis manifests were written without explicit resource requests, so each container silently picked up a 2Gi memory request. Combined with the web-app deployments already running in the same namespace, the aggregate requested memory exceeded the namespace's 4Gi `ResourceQuota` ceiling, and the API server rejected the pod admission before a pod object was even created — which is why `kubectl get pods` showed nothing rather than a Pending or Error state.

**Fix**
Added small, explicit `resources.requests`/`resources.limits` blocks to both `redis.yaml` (100m CPU / 256Mi memory) and `postgres.yaml` (250m CPU / 512Mi memory), overriding Autopilot's default injection with values appropriately sized for a low-traffic demo workload.

**Takeaway**
On GKE Autopilot, *every* container should declare explicit resource requests — omitting them doesn't mean "unbounded," it means "silently defaulted to a fairly large value (2Gi memory) that can blow through a namespace quota without any obviously-named error." This is a common surprise for engineers coming from standard GKE or self-managed clusters, where unspecified resources simply mean "unbounded, best-effort."

---

## 2. Postgres CrashLoopBackOff — `lost+found` blocking `initdb`

**Symptom**
`postgres-0` cycled through `CrashLoopBackOff` immediately after Redis's quota issue was fixed and the StatefulSet was allowed to schedule.

**Investigation**
`kubectl logs postgres-0 --previous` (reading the crashed container's last logs, since the current attempt was mid-crash-loop with minimal output) surfaced a clear Postgres startup error: `initdb` refused to initialize the data directory because it was not empty — it contained a `lost+found` directory.

**Root cause**
The PVC backing Postgres's data volume is provisioned on a GCE Persistent Disk formatted with ext4. Every ext4 filesystem reserves a `lost+found` directory at its root, used by `fsck` for recovering orphaned inodes after a filesystem check. Postgres's `initdb` requires the target data directory to be completely empty and refuses to proceed if it finds *any* pre-existing entries — including a filesystem-reserved directory that has nothing to do with the application.

**Fix**
Set `PGDATA=/var/lib/postgresql/data/pgdata` as an environment variable on the Postgres container, pointing Postgres at a subdirectory of the mounted volume rather than the volume's root. `initdb` then creates and initializes that subdirectory fresh, leaving the ext4-reserved `lost+found` entry untouched at the parent level.

**Takeaway**
This is a well-known but easy-to-miss gotcha specific to running Postgres on raw block-storage-backed PVCs (as opposed to a managed database service that abstracts this away). Anyone provisioning a StatefulSet's data directory directly onto a PV root should default to a `PGDATA` subdirectory rather than the volume root.

---

## 3. BigQuery Query 2 (pod/controller lifecycle events) returned zero rows despite confirmed real events

This was a two-stage investigation with two distinct, unrelated root causes stacked on top of each other.

**Symptom — stage 1**
After creating the Cloud Logging → BigQuery export sink and confirming (via `bq ls`) that the `events_*` table existed, `bq query` against it for Kubernetes lifecycle events returned zero rows, even though `kubectl get events -A` showed real cluster events had occurred.

**Investigation — stage 1**
Checked the timestamps: the sink was created *after* the events in question had already occurred and been logged.

**Root cause — stage 1**
Cloud Logging sinks are **not retroactive**. A sink only captures log entries generated after the sink's creation time; it cannot export historical log entries that were already written to Cloud Logging before the sink existed, even though those entries are still visible in the Cloud Logging console/API. This is a fundamental property of log sinks, not a misconfiguration.

**Fix — stage 1**
Triggered fresh events intentionally (scaling a deployment to force pod churn) so new log entries would be generated *after* the sink existed, then re-ran the query after allowing time for the BigQuery streaming export to catch up.

**Symptom — stage 2**
Even after triggering fresh events and confirming via `kubectl get events` that new `Killing` events were occurring in real time, the BigQuery query — filtered to `reason IN ('Killing', ...)` — still returned zero rows.

**Investigation — stage 2**
Removed the `reason` filter entirely and ran a broader diagnostic query against the same `events_*` table with no reason restriction. This surfaced real rows — but every single one had a `reason` from a different set entirely: `ScalingReplicaSet`, `SuccessfulCreate`, `SuccessfulDelete`, `ScaleUpFailed`. Not a single `Killing` event was present, despite `kubectl get events` clearly showing them occurring on the cluster in real time.

**Root cause — stage 2**
GKE's built-in Kubernetes-events-to-Cloud-Logging exporter does not forward every event `reason` visible via the Kubernetes API. Specifically, it forwards **controller-sourced** events (emitted by the Deployment/ReplicaSet controllers — `ScalingReplicaSet`, `SuccessfulCreate`, `SuccessfulDelete`, `ScaleUpFailed`, etc.) but drops **kubelet-sourced** events (emitted directly by the kubelet on each node — `Killing`, `Pulling`, `Pulled`, etc.). `kubectl get events` reads directly from the Kubernetes API server's event store, which has everything; the Cloud Logging exporter sits on a separate, narrower pipeline that only mirrors a subset of event sources.

**Fix — stage 2**
Rewrote the query's `reason IN (...)` filter to match the event reasons GKE's exporter actually forwards (the controller-sourced set), rather than the reasons visible in `kubectl get events`.

**Takeaway**
"The event exists in Kubernetes" and "the event exists in Cloud Logging/BigQuery" are not equivalent claims for GKE — the platform's built-in event exporter has an undocumented-in-practice scope narrower than the full Kubernetes events API. Anyone building alerting or dashboards on GKE events sourced from Cloud Logging needs to validate empirically which event reasons actually flow through, rather than assuming full parity with `kubectl get events`.

---

## 4. Cloud Monitoring panel: `INVALID_ARGUMENT` — filter field must be prefixed

**Symptom**
Building a Grafana panel against the Google Cloud Monitoring data source (for CPU/memory metrics, since BigQuery logs can't provide resource-utilization data) failed with:
```
The lefthand side of each expression must be prefixed with one of {group, metadata, metric, project, resource}.
```

**Root cause**
Cloud Monitoring's filter query language requires every filter key to be namespaced under one of a fixed set of prefixes (`resource.label.*`, `metric.label.*`, `metadata.system_labels.*`, etc.). Grafana's Cloud Monitoring query builder UI allowed typing a bare label name (`namespace_name`) into the filter field without enforcing or auto-adding the required prefix, producing a syntactically invalid filter that Cloud Monitoring's API correctly rejected.

**Fix**
Changed the filter field to the fully-qualified `resource.label.namespace_name`.

**A second, compounding issue in the same panel**
After fixing the prefix, a follow-up attempt to filter to *two* namespace values (`app-primary` and `app-secondary`) using two separate `=` filter rows failed with a different, more precise error:
```
resource.label.namespace_name has been AND'ed multiple times with EQUALS restrictions.
```
Grafana's builder ANDs multiple filter rows together by default, so two `=` rows on the same field is logically requesting a value that is simultaneously equal to two different strings — never satisfiable. The fix was to drop per-value filter rows entirely and instead use **Group By** on `resource.label.namespace_name` (with a `mean` group-by function and a `mean` alignment function), which correctly returns one time series per distinct namespace value in a single query.

**Takeaway**
Cloud Monitoring's filter syntax has hard structural requirements (mandatory prefixes, no native OR across repeated equality filters on one field) that Grafana's builder UI does not proactively validate or explain — the API's error messages are the actual source of truth here, and are worth reading character-by-character rather than assumed.

---

## 5. `bq` CLI failing inside a Workload-Identity pod: metadata server concealment

**Symptom**
While verifying Workload Identity by exec'ing into a debug pod running under a dedicated Kubernetes ServiceAccount bound to a GCP service account, `gcloud auth list` correctly showed the expected service account as active — but `bq ls` failed with:
```
MetadataServerException: The request is rejected. Please check if the metadata server is concealed.
```

**Investigation**
Since `gcloud auth list` succeeded (proving the identity binding itself was correct), the failure was isolated to `bq`'s specific credential-refresh code path rather than Workload Identity itself. Running `gcloud auth print-access-token` directly succeeded and returned a valid OAuth2 access token. Calling the BigQuery REST API directly with that token via `curl` succeeded and returned the expected table list.

**Root cause**
`bq`'s internal `gcloud` credential store, under certain conditions, attempts to refresh an **OIDC identity token** (`id_token`) from the GCE/GKE metadata server rather than a standard OAuth2 **access token**. GKE's metadata server concealment feature — a security control that blocks pods from reaching sensitive node-level metadata endpoints not relevant to their own Workload Identity-scoped credentials — rejects that specific identity-token request pattern, even though standard access-token requests (which is what virtually all GCP API calls actually authenticate with) are unaffected.

**Fix**
Bypassed the `bq` CLI's internal credential-refresh path entirely: used `gcloud auth print-access-token` to obtain a token directly, then called the BigQuery REST API with `curl` and a bearer-token header, which returned the correct result.

**Takeaway**
A tool-level authentication failure inside a Workload Identity pod doesn't necessarily mean Workload Identity is misconfigured — isolating whether the *binding* works (via `gcloud auth list` / `print-access-token`) versus whether a *specific client tool's* internal auth flow is compatible with GKE's metadata concealment is an important diagnostic split before assuming an IAM/binding problem.

---

## 6. `403 SERVICE_DISABLED` — Cloud Resource Manager API not enabled

**Symptom**
While provisioning the Grafana BigQuery-reader service account, a `gcloud` command failed with a `403` error indicating the Cloud Resource Manager API was disabled for the project.

**Root cause**
A newly created GCP project only has a small set of APIs enabled by default. Several `gcloud`/IAM operations depend on the Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`) even when the command being run doesn't obviously reference "resource manager" by name — it's a transitive dependency for project-level IAM policy operations.

**Fix**
```bash
gcloud services enable cloudresourcemanager.googleapis.com --project=schwab-sre-assessment
```

**Takeaway**
On a fresh GCP project, `SERVICE_DISABLED` errors are common and expected the first time each underlying API is touched — the fix is almost always a one-line `gcloud services enable`, not a deeper configuration problem.

---

## Cross-cutting observation

A theme across several of these incidents (#1, #3, #4) is that **defaults and abstractions in managed platforms (Autopilot resource injection, GKE's event exporter scope, Grafana's Cloud Monitoring query builder) can silently diverge from what a first-time user would assume**, and the failure signatures they produce (empty results, missing pods with no error, a generic `INVALID_ARGUMENT`) rarely point directly at the actual cause. In each case, the fix came from comparing what *should* be true (e.g., "these events exist, I can see them with kubectl") against what the platform *actually* reported at each layer, rather than from documentation alone.

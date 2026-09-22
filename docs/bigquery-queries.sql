-- Query 1: Error rate proxy (stderr vs total log volume), app namespaces only
-- NOTE: near-1.0 across the board is a known limitation of this demo image
-- (gcr.io/google-samples/hello-app writes normal output to stderr), not a
-- real error condition -- see docs/design-decisions.md.
WITH combined AS (
  SELECT timestamp, resource.labels.namespace_name AS namespace, 'stderr' AS stream
  FROM `schwab-sre-assessment.gke_logs.stderr_*`
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND resource.labels.namespace_name IN ('app-primary', 'app-secondary')
  UNION ALL
  SELECT timestamp, resource.labels.namespace_name AS namespace, 'stdout' AS stream
  FROM `schwab-sre-assessment.gke_logs.stdout_*`
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND resource.labels.namespace_name IN ('app-primary', 'app-secondary')
)
SELECT
  TIMESTAMP_TRUNC(timestamp, MINUTE) AS bucket,
  namespace,
  COUNTIF(stream = 'stderr') AS error_count,
  COUNT(*) AS total_count,
  SAFE_DIVIDE(COUNTIF(stream = 'stderr'), COUNT(*)) AS error_rate
FROM combined
GROUP BY bucket, namespace
ORDER BY bucket DESC;

-- Query 2: Pod/controller lifecycle events by namespace, from Kubernetes events
-- NOTE: kubelet-sourced events (e.g. "Killing") are not forwarded by GKE's
-- Cloud Logging event exporter -- only controller-level reasons below are
-- actually present in this table. Confirmed by diagnostic query during build
-- -- see docs/troubleshooting.md.
SELECT
  jsonPayload.involvedobject.namespace AS namespace,
  jsonPayload.involvedobject.name AS obj_name,
  jsonPayload.reason AS reason,
  COUNT(*) AS event_count
FROM `schwab-sre-assessment.gke_logs.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND jsonPayload.reason IN ('SuccessfulCreate', 'SuccessfulDelete', 'FailedCreate', 'BackOff', 'ScaleUpFailed')
GROUP BY namespace, obj_name, reason
ORDER BY event_count DESC;

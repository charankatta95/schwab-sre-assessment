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
ORDER BY bucket DESC

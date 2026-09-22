SELECT
  jsonPayload.involvedobject.namespace AS namespace,
  jsonPayload.involvedobject.name AS obj_name,
  jsonPayload.reason AS reason,
  COUNT(*) AS event_count
FROM `schwab-sre-assessment.gke_logs.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND jsonPayload.reason IN ('SuccessfulCreate', 'SuccessfulDelete', 'FailedCreate', 'BackOff', 'ScaleUpFailed')
GROUP BY namespace, obj_name, reason
ORDER BY event_count DESC

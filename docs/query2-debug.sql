SELECT
  timestamp,
  jsonPayload.reason AS reason,
  jsonPayload.involvedobject.name AS obj_name,
  jsonPayload.involvedobject.namespace AS namespace
FROM `schwab-sre-assessment.gke_logs.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
ORDER BY timestamp DESC
LIMIT 20

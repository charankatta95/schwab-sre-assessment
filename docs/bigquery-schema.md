# BigQuery Log Schema

## stderr_20260922
```json
[
  {
    "mode": "NULLABLE",
    "name": "logName",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "type",
        "type": "STRING"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "namespace_name",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "container_name",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "project_id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "cluster_name",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "pod_name",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "labels",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "resource",
    "type": "RECORD"
  },
  {
    "mode": "NULLABLE",
    "name": "textPayload",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "message",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "pid",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "jsonPayload",
    "type": "RECORD"
  },
  {
    "mode": "NULLABLE",
    "name": "timestamp",
    "type": "TIMESTAMP"
  },
  {
    "mode": "NULLABLE",
    "name": "receiveTimestamp",
    "type": "TIMESTAMP"
  },
  {
    "mode": "NULLABLE",
    "name": "severity",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "insertId",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "requestMethod",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "requestUrl",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "requestSize",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "status",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "responseSize",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "userAgent",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "remoteIp",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "serverIp",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "referer",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheLookup",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheHit",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheValidatedWithOriginServer",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheFillBytes",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "protocol",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "httpRequest",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_k8s_app",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_topology_kubernetes_io_zone",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "compute_googleapis_com_resource_name",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_topology_kubernetes_io_region",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_pod_template_hash",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "logging_gke_io_top_level_controller_name",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_app",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "logging_gke_io_top_level_controller_type",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_component",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_pod_template_generation",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "k8s_pod_controller_revision_hash",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "labels",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "id",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "producer",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "first",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "last",
        "type": "BOOLEAN"
      }
    ],
    "mode": "NULLABLE",
    "name": "operation",
    "type": "RECORD"
  },
  {
    "mode": "NULLABLE",
    "name": "trace",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "spanId",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "traceSampled",
    "type": "BOOLEAN"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "file",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "line",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "function",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "sourceLocation",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "uid",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "index",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "totalSplits",
        "type": "INTEGER"
      }
    ],
    "mode": "NULLABLE",
    "name": "split",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "id",
        "type": "STRING"
      }
    ],
    "mode": "REPEATED",
    "name": "errorGroups",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "container",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "application",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "service",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "workload",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "apphub",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "container",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "application",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "service",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "workload",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "apphubDestination",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "container",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "application",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "service",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "workload",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "apphubSource",
    "type": "RECORD"
  }
]
```

## events_20260922
```json
[
  {
    "mode": "NULLABLE",
    "name": "logName",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "type",
        "type": "STRING"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "project_id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "cluster_name",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "labels",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "resource",
    "type": "RECORD"
  },
  {
    "mode": "NULLABLE",
    "name": "textPayload",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "lasttimestamp",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "kind",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "reportingcomponent",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "reportinginstance",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "message",
        "type": "STRING"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "name",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "kind",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "resourceversion",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "uid",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "apiversion",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "namespace",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "involvedobject",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "component",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "source",
        "type": "RECORD"
      },
      {
        "mode": "NULLABLE",
        "name": "reason",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "type",
        "type": "STRING"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "resourceversion",
            "type": "STRING"
          },
          {
            "fields": [
              {
                "mode": "NULLABLE",
                "name": "fieldstype",
                "type": "STRING"
              },
              {
                "mode": "NULLABLE",
                "name": "time",
                "type": "STRING"
              },
              {
                "mode": "NULLABLE",
                "name": "apiversion",
                "type": "STRING"
              },
              {
                "mode": "NULLABLE",
                "name": "operation",
                "type": "STRING"
              },
              {
                "mode": "NULLABLE",
                "name": "manager",
                "type": "STRING"
              }
            ],
            "mode": "REPEATED",
            "name": "managedfields",
            "type": "RECORD"
          },
          {
            "mode": "NULLABLE",
            "name": "uid",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "creationtimestamp",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "namespace",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "name",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "metadata",
        "type": "RECORD"
      },
      {
        "mode": "NULLABLE",
        "name": "apiversion",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "jsonPayload",
    "type": "RECORD"
  },
  {
    "mode": "NULLABLE",
    "name": "timestamp",
    "type": "TIMESTAMP"
  },
  {
    "mode": "NULLABLE",
    "name": "receiveTimestamp",
    "type": "TIMESTAMP"
  },
  {
    "mode": "NULLABLE",
    "name": "severity",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "insertId",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "requestMethod",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "requestUrl",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "requestSize",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "status",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "responseSize",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "userAgent",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "remoteIp",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "serverIp",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "referer",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheLookup",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheHit",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheValidatedWithOriginServer",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "cacheFillBytes",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "protocol",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "httpRequest",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "id",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "producer",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "first",
        "type": "BOOLEAN"
      },
      {
        "mode": "NULLABLE",
        "name": "last",
        "type": "BOOLEAN"
      }
    ],
    "mode": "NULLABLE",
    "name": "operation",
    "type": "RECORD"
  },
  {
    "mode": "NULLABLE",
    "name": "trace",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "spanId",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "traceSampled",
    "type": "BOOLEAN"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "file",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "line",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "function",
        "type": "STRING"
      }
    ],
    "mode": "NULLABLE",
    "name": "sourceLocation",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "uid",
        "type": "STRING"
      },
      {
        "mode": "NULLABLE",
        "name": "index",
        "type": "INTEGER"
      },
      {
        "mode": "NULLABLE",
        "name": "totalSplits",
        "type": "INTEGER"
      }
    ],
    "mode": "NULLABLE",
    "name": "split",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "mode": "NULLABLE",
        "name": "id",
        "type": "STRING"
      }
    ],
    "mode": "REPEATED",
    "name": "errorGroups",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "container",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "application",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "service",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "workload",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "apphub",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "container",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "application",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "service",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "workload",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "apphubDestination",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "container",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "location",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "application",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "service",
        "type": "RECORD"
      },
      {
        "fields": [
          {
            "mode": "NULLABLE",
            "name": "id",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "environmentType",
            "type": "STRING"
          },
          {
            "mode": "NULLABLE",
            "name": "criticalityType",
            "type": "STRING"
          }
        ],
        "mode": "NULLABLE",
        "name": "workload",
        "type": "RECORD"
      }
    ],
    "mode": "NULLABLE",
    "name": "apphubSource",
    "type": "RECORD"
  }
]
```

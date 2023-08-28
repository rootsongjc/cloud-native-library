---
title: Streaming Service Logs
description: Enable service streaming log to show workload logs
---

:::warning Alpha Feature
Streaming service logs is an Alpha feature and is not recommended for production usage. 
:::

TSB has the feature to view service logs directly from the TSB UI. Using this feature you will be able to view near real time logs from applications and sidecars for troubleshooting.

:::note Log Storage
TSB **DOES NOT** store any of your logs in a storage system. Logs are streamed directly from Clusters to Management Plane. 
:::

## Management Plane

To enable streaming service logs in the Management Plane, add `streamingLogEnabled: true` under oap components in your `ManagementPlane` CR or Helm values then apply. 

```yaml
spec:
  hub: <registry_location>
  organization: <organization>
    ...
  components:
    ...
    oap:
      streamingLogEnabled: true  
```

## Control Plane

For each onboarded cluster, add `streamingLogEnabled: true` under oap components in your `ControlPlane` CR or Helm values then apply.

```yaml
spec:
  hub: <registry_location>
  managementPlane:
    ...
  telemetryStore:
    elastic:
      ...
  components:
    ...
    oap:
      streamingLogEnabled: true
```

## Streaming Service Log UI

To see the service logs in the TSB UI, go to Services and select a Controlled service. A controlled service is a service that is part of the mesh and has a proxy we can configure. 

You will see the Logs tab and you can select which containers you want to see the logs for, then start streaming the logs by clicking the Start button.

Following image shows the service logs for a service with a sidecar. You can select up to two containers and thus will be able to see both service and sidecar log side by side.

![](../../assets/operations/streaming-log-service.png)

Following image shows the service log for the TSB gateway. 

![](../../assets/operations/streaming-log-gateway.png)

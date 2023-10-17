---
title: Management Plane DR
---

import Steps from "@theme/Steps";

# Restoring a failed Management Plane component

_In the case that the Tetrate Management Plane fails, you will need to restore the Management Plane to resume normal operational status.  This guide provides an overview of the process, and you should refer to [Tetrate Technical Support](https://tetrate.io/contact-us/) for assistance with this procedure._

To prepare for unexpected failure of the Management components, we recommend that you consider the following recommendations:

 * Either maintain the Postgres database in a reliable, redundant cluster, or (in the case of TSE), make use of the [regular Postgres backups](https://docs.tetrate.io/service-express/administration/postgres).
 * Maintain a backup of the **iam-signing-key**
 * If preserving metrics is important, maintain the ElasticSearch database in a reliable, redundant cluster, or make regular backups so that it can be restored if necessary.

## Overview

Should the [Management Plane fail](scenarios#failure-of-management-plane) or the [cluster hosting the Management plane become non-operational](scenarios#failure-of-management-cluster), you will need to restore the Management Plane to resume normal operation status.  The recovery is done using a helm base install.
This scenario will walk through the task of restoring configuration from our failed Management Cluster on a new Management Cluster.

### Prerequisites

This guide makes the following assumptions:

 * The PostgreSQL Database (configuration) is available.  Either, the database is external to failed cluster, or it can be [restored from a backup (TSE only)](http://docs.tetrate.io/service-express/administration/postgres)
 * The ElasticSearch Database (metrics) is available.  Either, the database is external to failed cluster, it can be restored from a backup, or a fresh (empty) ElasticSearch database can be used and loss-of-metrics tolerated
 * All Certificates for the new Management Plane cluster use the same Root Certificate Authority as previous failed cluster
 * You can update any DNS record used to discover the Management Plane
 * You have a backup of the iam-signing-key

## Procedure

Please work with [Tetrate Technical Support](https://tetrate.io/contact-us/) to go through the following procedure:

<Steps headingDepth={3}>

<ol>
<li>

### Deploy a new cluster

Deploy new cluster where the Management Plane will be restored to

</li>
<li>

### Install Dependencies

Install the required dependencies into the cluster. These dependencies will likely include:
 * Cert-Manager (if you're not using the bundled cert-manager instance) and related issuers/certificates. Ensure you use the same root CA
 * Any secrets that hold credentials/certificates for the Management Plane
 * The **iam-signing-key** from the failed Management Plane cluster - optional

Install the **iam-signing-key** secret using `kubectl apply`. If this is not possible, you will need to reconfigure each Control Plane with a fresh secret later in this procedure.

</li>
<li>

### Prepare the configuration

Using the same **mp-values.yaml** as failed cluster, update any required fields such as hub or registry, or any other environment dependent fields if required.

There is no need to update the Elastic/Postgres configuration if using external IP endpoints, but may need to adjust firewall rules.

</li>
<li>

### Install the Management Plane

Perform the helm install for Management Plane using **mp-values.yaml**, and monitor progress using:

```bash
kubectl get pod -n tsb
kubectl logs -f -n tse -l name=tsb-operator
```

In the case of Tetrate Service Express (TSE), the components are installed in the **tse** namespace (not **tsb**).

</li>
<li>

### Get the Management Plane address

Once installation has completed, obtain the **front envoy** public ip address, for example:

```bash
kubectl get svc -n tsb envoy
```

Log into the UI with Envoy IP Address:

 1. Verify that your Tetrate configuration has been preserved in the Postgres DB
 1. Check Elastic historical data if available

</li>
<li> 

### Update DNS

Update the DNS A Record used to locate the Management Plane with the new IP Address acquired in step 5.  Remote control plane clusters will use this DNS record to communicate with the Management Plane

Propagation may take time.  Once the change has propagated, verify that you can access the Management Plane UI using the FQDN

</li>
<li>

### Verify Control Plane operation

In the Management Plane UI, verify that the workload cluster Control Planes are connecting and synchronising with the new Management Plane

:::warning Refresh the Control Plane tokens

The **iam-signing-key** is used to generate, validate and rotate tokens that are given to the Control Plane Clusters for communication to the Management Plane.

If you could not recover and restore the original **iam-signing-key**, you will need to refresh the tokens on each Control Plane manually:

 1. Log into each Control Plane cluster
 1. Rotate tokens by deleting the old tokens: 

    ```bash
    kubectl delete secret otel-token oap-token ngac-token xcp-edge-central-auth-token -n istio-system
    ```

  1. Verify that the Control Planes are now connecting to and synchronising with the new Management Plane

:::

</li>
</ol>
</Steps>

With a successful restore of a new Management Plane, you will have fully recovered from the failure and your Workload Clusters will be under the control of the new Management Plane instance.


## Troubleshooting

The Management Plane and Control Plane installations are managed by operators.  If you make a configuration change, you can monitor the operator logs to watch progress and identify any errors.

### The Control Planes won't synchronize

Check the logs of ControlPlane Envoy, looking for errors regarding connections to the Management Plane or errors regarding token validation:

```bash
kubectl logs deploy/edge -n istio-system -f
```

Delete the existing tokens on the Control Plane as described above, and verify that these tokens are re-generated on the Control Plane. 

```bash
kubectl get secrets otel-token oap-token ngac-token xcp-edge-central-auth-token -n istio-system
```

If the tokens are not regenerated:

 * Check the firewall rules between the Control Pane instance and the new Management Plane instance, and ensure that connections are allowed
 * Ensure that the Management Plane is using the same Root CA

### Can’t Access external components such as postgres

1. Validate the firewall rules to postgres or any other external component.
1. Verify the credentials passed via helm or in **mp-values.yaml**
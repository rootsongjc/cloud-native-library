---
title: Using The Debug Container
Description: How to run and use the  debug container
---

import vars from "../_vars.json";

Tetrate Service Bridge (TSB) is a complex collection of components that are interconnected using various protocols. This is probably also true for your applications deployed over the service mesh that TSB provides. In many cases you will need to check, test, and verify the network connectivity within the various TSB components to make sure that the system is working as expected.

To save you some time to create a debugging environment in the Kubernetes clusters, Tetrate provides a debug container that comes with most of the toolsets needed to validate the network status already installed. For example, tools such as `ping`, `curl`, `gpcurl`, `dig`, etc are already installed in this container.

## Using the debug container

This debug container can be deployed to any cluster as long as the appropriate image registry can be reached to download the container image.

The container image is included in the TSB distribution and will be synced to your registry along with the rest of the images when you run the [`tctl install image-sync` command](../setup/requirements-and-download#sync-tetrate-service-bridge-images).

To deploy the debug container, run the following command. Replace `<registry-location>` with the registry URL where you synced the TSB images.

<pre><code>
{`kubectl run debug-container --image <registry-location>/tetrate-troubleshoot:${vars.versionNumber} -it -- ash`}
</code></pre>

Once the pod is created, you will be placed in a shell within the debug container and you will be able to run necessary commands for troubleshooting.

### Checking the network connectivity

If you want to check the network connectivity from the TSB cluster to the datastore you use (we assume PostgreSQL for this example), you can run the following command:

```bash
curl -v telnet://<postgres_IP>:5432
```

Or use the PostgreSQL client command `psql` to validate the credentials.

```bash
psql -h my.postgres.local -P 5432 -U myUser
```

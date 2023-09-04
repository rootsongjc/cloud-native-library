---
title: Elasticsearch wipe procedure
menu-title: Wipe Procedure
description: Follow the procedure described to clean up Elasticsearch data.
---

In some situations, due to data model changes in Elasticsearch indexes, it is
required that you wipe existing indexes and templates so the new version of OAP can function properly.

The procedure below describes how to wipe such data from Elasticsearch and
ensure that the OAP component will start up correctly.

:::warning Scale down replicas
Make sure to follow steps 1 and 2 before proceeding
:::

**1. Scale down to 0 replicas the `oap-deployment` deployment in the control plane namespace.**

:::warning
This needs to be done in all CP clusters onboarded in TSB.
:::

```bash{outputLines: 2}
kubectl -n ${CONTROL_NAMESPACE} scale deployment oap-deployment
--replicas=0
```

**2. Scale down to 0 replicas the `oap` deployment in the management namespace.**

```bash
kubectl -n ${MANAGEMENT_NAMESPACE} scale deployment oap --replicas=0
```

**3. Execute the following commands to delete templates and indexes in Elasticsearch.**

```bash
es_host=localhost
es_port=9200
es_user=<USER>
es_pass=<PASS>
for tmpl in $(curl -u "$es_user:$es_pass" -sS https://$es_host:$es_port/_cat/templates | \
  egrep "skywalking" | \
  awk '{print $1}'); do echo "$tmpl: "; curl -u "$es_user:$es_pass" -sS https://$es_host:$es_port/_index_template/$tmpl -XDELETE; echo "\n";
done
for idx in $(curl -u "$es_user:$es_pass" https://$es_host:$es_port/_cat/indices | \
  egrep "skywalking" | \
  awk '{print $3}'); do echo "$idx: "; curl -u "$es_user:$es_pass" https://$es_host:$es_port/$idx -XDELETE; echo "\n";
done
```

:::note Selecting dates
If you want to delete a particular date of indices instead of everything, you can just add a grep to the command above, having something like ```...curl -u "$es_user:$es_pass" https://$es_host:$es_port/_cat/indices | grep "20221006"| ...``` With this example, you will delete all indices created on the 6th of October 2022.
:::

:::note Elasticsearch options
The commands above assume a plain HTTP Elasticsearch instance with no auth.
Next to setting `<es_host>` and `<es_port>` appropriately, you will need to add
basic auth if required by supplying `-u <es_user>:<es_pass>` to the `curl`
commands above, or set the scheme to `https` if needed.
:::


**4. Scale up the `oap` deployment in the management namespace.**

```bash
kubectl -n ${MANAGEMENT_NAMESPACE} scale deployment oap --replicas=1
```

**Keep an eye on the logs of the new OAP pod in the management plane namespace, if there are no errors and the pod is running fine, you can continue with the next steps.**

:::warning OAP availability
Ensure OAP starts correctly in the management plane before continuing
with this procedure. The management plane pods for this component create the
needed index templates and indices required by the system, so you need to ensure
OAP is up and running before moving on to scale up the control plane
components.
:::

**5. Scale up the `oap-deployment` deployment in the control plane namespace.**

:::warning
This needs to be done in all CP clusters onboarded in TSB.
:::

```bash{outputLines: 2}
kubectl -n ${CONTROL_NAMESPACE} scale deployment oap-deployment \
--replicas=1
```

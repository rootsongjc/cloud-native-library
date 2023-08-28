---
title: Security
description: Use TSB security settings to limit access from outside the workspace.
weight: 10
---

In this scenario, you will learn how to use TSB security settings to limit access from outside the workspace. This helps enhance the security of your environment by controlling communication between services.

### Prerequisites

Before proceeding, ensure that you have completed the following tasks:

- Familiarize yourself with TSB concepts.
- Install the TSB demo environment.
- Deploy the Istio Bookinfo sample application.
- Create a Tenant, Workspace, and Config Groups.
- Configure Permissions for teams and users.
- Set up an Ingress Gateway.
- Check service topology and metrics using observability tools.
- Configure Traffic Shifting.

### Deploy a "sleep" Service

First, let's deploy a "sleep" service in another namespace that doesn't belong to the bookinfo application workspace. This will be used to test the security settings.

Create the following `sleep.yaml` file:

```yaml
# ... (The contents of sleep.yaml)
```

Depending on your environment (Standard Kubernetes or OpenShift), use the appropriate commands to deploy the `sleep` service:

<details>
<summary>Standard Kubernetes</summary>

```bash
kubectl create namespace sleep
kubectl label namespace sleep istio-injection=enabled --overwrite=true
kubectl apply -n sleep -f sleep.yaml
```

After waiting for the configuration to propagate, you can call the bookinfo product page from the `sleep` service pod:

```bash
kubectl exec "$(kubectl get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -o "<title>.*</title>"
```

</details>

<details>
<summary>OpenShift</summary>

```bash
oc create namespace sleep
oc label namespace sleep istio-injection=enabled

cat <<EOF | oc -n sleep create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF

oc adm policy add-scc-to-group anyuid \
    system:serviceaccounts:sleep

oc apply -n sleep -f sleep.yaml
```

After waiting for the configuration to propagate, you can call the bookinfo product page from the `sleep` service pod:

```bash{promptUser: Alice}
oc exec "$(oc get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -o "<title>.*</title>"
```

</details>

You should see the output:

```text
<title>Simple Bookstore App</title>
```

This indicates that the communication between services from outside the workspace and the bookinfo application workspace is allowed.

### Create Security Setting

You can configure security settings to limit communication between services from different workspaces or clusters. In this scenario, we will configure communication between services in the same workspace and cluster.

#### Using the UI

1. Under **Tenant**, select **Workspaces**.
2. On the `bookinfo-ws` Workspace card, click on **Security Groups**.
3. Click on the `bookinfo-security` Security Group you created earlier.
4. Select the **Security Settings** tab.
5. Click **Add new...** to create a new Security Setting with the default name `default-setting`.
6. Rename the new Security Setting to `bookinfo-security-settings`.
7. Expand **bookinfo-security-settings** to display additional configurations: Authentication Settings and Authorization Settings.
8. Click **Authentication Settings** and set the Traffic Mode field to REQUIRED.
9. Click **Authorization Settings** and set the Mode field to WORKSPACE.
10. Click **Save Changes**.

#### Using tctl

Create the following `security.yaml` file:

```yaml
# ... (The contents of security.yaml)
```

Apply the configuration using `tctl`:

```bash
tctl apply -f security.yaml
```

### Verify Security Settings

After waiting for the configuration to propagate, test the security settings by attempting to access services from the `sleep` service.

<details>
<summary>Standard Kubernetes</summary>

```bash
kubectl exec "$(kubectl get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://productpage.bookinfo:9080/productpage -v
```

</details>

<details>
<summary>OpenShift</summary>

```bash
oc exec "$(oc get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://productpage.bookinfo:9080/productpage -v
```

</details>

You should receive an output similar to:

```text
HTTP/1.1 403 Forbidden
...
RBAC: access denied
```

This indicates that the communication from the `sleep` service to the `bookinfo` product page is denied due to the security settings. This ensures that services from outside the workspace are not allowed to access services within the application workspace.

#### Allow Access to a Specific Service

To allow access to a specific service within

 the security group, you can add a `ServiceSecuritySetting` to override the rules for that service.

<details>
<summary>Using tctl</summary>

Create the following `service-security.yaml` file:

```yaml
# ... (The contents of service-security.yaml)
```

Apply the configuration using `tctl`:

```bash
tctl apply -f service-security.yaml
```

</details>

After waiting for the configuration to propagate, test the access to the reviews service from the `sleep` service.

<details>
<summary>Standard Kubernetes</summary>

```bash
kubectl exec "$(kubectl get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://reviews.bookinfo:9080/reviews/0 -v
```

</details>

<details>
<summary>OpenShift</summary>

```bash
oc exec "$(oc get pod -l app=sleep -n sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep -- curl http://reviews.bookinfo:9080/reviews/0 -v
```

</details>

You should receive a successful response:

```text
HTTP/1.1 200 OK
...
```

This indicates that the communication from the `sleep` service to the `bookinfo` reviews service is allowed because you added a `ServiceSecuritySetting` to allow access.

By following these steps, you have successfully configured TSB security settings to limit access from outside the workspace, enhancing the security of your environment.

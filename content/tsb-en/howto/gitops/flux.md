---
title: Configuring Flux CD for GitOps
description: How to configure Flux CD to deploy TSB resources defined in git repositories.
weight: 2
---

This document explains how you can configure [Flux CD](https://fluxcd.io/) with
Helm and GitHub integration to deploy a TSB application to a target cluster.

:::note
This document assumes that:
- [Flux](https://fluxcd.io/docs/installation/) version 2 CLI is installed.
- [Helm](https://helm.sh/docs/intro/install) CLI is installed.
- TSB is up and running, and GitOps [has been
  enabled](../../operations/features/configure_gitops) for the target cluster.
:::

## Cluster setup

First, install Flux on the target cluster with a [GitHub
integration](https://fluxcd.io/docs/cmd/flux_bootstrap_github/). To do that,
use the following command under the target cluster kubernetes context.

:::note
You will need a GitHub [Personal Access
Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
(PAT) to input in the following command.
:::

```bash{promptUser: "alice"}
$ flux bootstrap github \
  --owner=your-org \
  --repository=git-ops \
  --path=./clusters/cluster-01
```

:::note
Add `--personal --private` flags if you use your personal GitHub account for testing purposes.
:::

This sets up Flux with the needed configurations for a cluster called
`cluster-01` in a GitHub repository named `git-ops` under the
`clusters/cluster-01/` directory.

:::note
Run `flux logs -A --follow` command in a different shell for
debugging purposes.
:::

You can run this command to do a generic status check:

```bash{promptUser: "alice"}
$ flux check
► checking prerequisites
✔ Kubernetes 1.20.15-gke.2500 >=1.20.6-0
► checking controllers
✔ helm-controller: deployment ready
► ghcr.io/fluxcd/helm-controller:v0.20.1
✔ kustomize-controller: deployment ready
► ghcr.io/fluxcd/kustomize-controller:v0.24.2
✔ notification-controller: deployment ready
► ghcr.io/fluxcd/notification-controller:v0.23.4
✔ source-controller: deployment ready
► ghcr.io/fluxcd/source-controller:v0.24.0
✔ all checks passed
```

Under the hood, Flux uses a
[`Kustomization`](https://fluxcd.io/docs/components/kustomize/kustomization/)
with a
[`GitRepository`](https://fluxcd.io/docs/components/source/gitrepositories/)
source to store its own resources.

You can query its status:

```bash{promptUser: "alice"}
$ flux get all
NAME                     	REVISION    	SUSPENDED	READY	MESSAGE
gitrepository/flux-system	main/36dff73	False    	True 	stored artifact for revision 'main/36dff739b5ae411a7b4a64010d42937bd3ae4d25'

NAME                     	REVISION    	SUSPENDED	READY	MESSAGE
kustomization/flux-system	main/36dff73	False    	True 	Applied revision: main/36dff73
```

Meanwhile, you will see something like this in the logs:

```sh
2022-04-24T20:42:06.921Z info Kustomization/flux-system.flux-system - server-side apply completed
2022-04-24T22:51:30.431Z info GitRepository/flux-system.flux-system - artifact up-to-date with remote revision: 'main/36dff739b5ae411a7b4a64010d42937bd3ae4d25'
```

Since Flux is up and running now, the next step is to push new configurations
to the `git-ops` repository for the `cluster-01` cluster. You can clone the
repository and `cd` into `clusters/cluster-01` for the next steps.

## Application setup

There are [several ways](https://fluxcd.io/docs/guides/repository-structure/)
to structure your GitOps repositories. In this example, and for simplicity
reasons, the same repository is used for both cluster and application configurations.

The goal for this section is to deploy the Helm chart of a
[Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) application and its
TSB resources. 

First, create the `bookinfo` namespace with sidecar injection:
```bash{promptUser: "alice"}
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

Then, create a
[`HelmRelease`](https://fluxcd.io/docs/guides/helmreleases/) Flux resource with a
[`GitRepository`](https://fluxcd.io/docs/components/source/gitrepositories/) 
source for Bookinfo.

:::note
The alternative to `GitRepository` is a
[`HelmRepository`](https://fluxcd.io/docs/components/source/helmrepositories/),
which is not covered in this document.
:::

If the `bookinfo` TSB helm chart definition is stored in the `apps/bookinfo`
directory, create the `HelmRelease` resource in `clusters/cluster-01/bookinfo.yaml`.

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: bookinfo
  namespace: flux-system
spec:
  chart:
    spec:
      chart: ./apps/bookinfo
      sourceRef:
        kind: GitRepository
        name: flux-system
  interval: 1m0s
  install:
    createNamespace: true
  targetNamespace: bookinfo
```

Note that:
- The `HelmRelease` will be created in the `flux-system` namespace, while the resources
defined by the Helm chart of the `apps/bookinfo` chart of the release will be deployed
in the `bookinfo` target namespace.
- Since `spec.chart.spec.version` is not specified, Flux will use _latest_ chart version.
- `GitRepository.name` is `flux-system` since that's the name Flux uses internally for bootstrapping.

Next, add and push the file into git and watch the flux logs. You will see something like this:

```sh
2022-04-25T08:02:37.233Z info HelmRelease/bookinfo.flux-system - reconcilation finished in 49.382555ms, next run in 1m0s
2022-04-25T08:02:37.980Z info HelmChart/flux-system-bookinfo.flux-system - Discarding event, no alerts found for the involved object
2022-04-25T08:02:45.784Z error HelmChart/flux-system-bookinfo.flux-system - reconciliation stalled invalid chart reference: stat /tmp/helmchart-flux-system-flux-system-bookinfo-4167124062/source/apps/bookinfo: no such file or directory
```

This is because the helm chart has not been pushed to the `apps/bookinfo` directory yet.

Note that instead of parsing the flux logs, you can also query the resources
with `kubectl`:
- `kubectl get helmreleases -A`
- `kubectl get helmcharts -A`

Next, create the helm chart. Create the `apps/` directory, enter it and run:

```bash{promptUser: "alice"}
$ helm create bookinfo
```

This creates the following file tree:

```bash{promptUser: "alice"}
$ tree
.
+-- bookinfo
    +-- Chart.yaml
    +-- charts
    +-- templates
    |   +-- NOTES.txt
    |   +-- _helpers.tpl
    |   +-- deployment.yaml
    |   +-- hpa.yaml
    |   +-- ingress.yaml
    |   +-- service.yaml
    |   +-- serviceaccount.yaml
    |   \-- tests
    |       \-- test-connection.yaml
    \-- values.yaml

4 directories, 10 files
```
Then, `cd` into `bookinfo/`.

For simplicity reasons, remove the following not-needed content:

```bash{promptUser: "alice"}
$ rm -rf values.yaml charts templates/NOTES.txt templates/*.yaml templates/tests/
```

Next, edit the `Chart.yaml`. A minimal content looks like this:

```yaml
apiVersion: v2
name: bookinfo
description: TSB bookinfo Helm Chart.
type: application
version: 0.1.0
appVersion: "0.1.0"
``` 

Next, add the Bookinfo definitions to the `templates/` directory,
gathering them from Istio's repository:

```bash{promptUser: "alice"}
curl https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml -o bookinfo.yaml
```

Once we have the bookinfo deployment, we'll add the TSB configuration resources in a
`templates/tsb.yaml` file. When creating the TSB configurations, a best practice is to
put all them inside a `List` resource. This will enforce a strict order when applying
them into the cluster, and you will be able to guarantee that the resources that are at
higher levels of the TSB resource hierarchy are applied first, and you won't hit issues
due to [Helm resource ordering limitations](https://github.com/helm/helm/issues/8439).

:::note
For this example, an ingress gateway it's used for the application that will be
configured by the first resource configuration below. You can read more about
this
[here](https://docs.tetrate.io/service-bridge/1.4.x/en-us/refs/install/dataplane/v1alpha1/spec).

Also make sure you change _your-org_ and _your-tenant_ for actual values.
:::

```yaml
apiVersion: v1
kind: List
items:
# Create an ingress gateway deployment that will be the entry point to
# the bookinfo application
- apiVersion: install.tetrate.io/v1alpha1
  kind: IngressGateway
  metadata:
    namespace: bookinfo
    name: tsb-gateway-bookinfo
  spec: {}
# Create the workspace and gateway group that capture the namespaces where
# the bookinfo application will run
- apiVersion: tsb.tetrate.io/v2
  kind: Workspace
  metadata:
    name: bookinfo
    annotations:
      tsb.tetrate.io/organization: your-org
      tsb.tetrate.io/tenant: your-tenant
  spec:
    namespaceSelector:
      names:
        - "*/bookinfo"
- apiVersion: gateway.tsb.tetrate.io/v2
  kind: Group
  metadata:
    name: bookinfo-gg
    annotations:
      tsb.tetrate.io/organization: your-org
      tsb.tetrate.io/tenant: your-tenant
      tsb.tetrate.io/workspace: bookinfo
  spec:
    namespaceSelector:
      names:
        - "*/*"
    configMode: BRIDGED
# Expose the productpage service in the application ingress
- apiVersion: gateway.tsb.tetrate.io/v2
  kind: IngressGateway
  metadata:
    name: bookinfo-gateway
    annotations:
      tsb.tetrate.io/organization: your-org
      tsb.tetrate.io/tenant: your-tenant
      tsb.tetrate.io/workspace: bookinfo
      tsb.tetrate.io/gatewayGroup: bookinfo-gg
  spec:
    workloadSelector:
      namespace: bookinfo
      labels:
        app: tsb-gateway-bookinfo
    http:
      - name: productpage
        port: 80
        hostname: "bookinfo.example.com"
        routing:
          rules:
            - route:
                host: "bookinfo/productpage.bookinfo.svc.cluster.local"
                port: 9080
---
```

Before pushing, test that the chart is well constructed:

```bash{promptUser: "alice"}
$ helm install bookinfo --dry-run .
```

It should print the rendered resources as YAML.

Now it's time to push them and check the flux logs.

If GitOps is properly configured in the cluster, pushing this chart will create
the corresponding Kubernetes and TSB resources:

```bash{promptUser: "alice"}
kubectl get pods -n bookinfo
NAME                                        READY   STATUS    RESTARTS   AGE
details-v1-79f774bdb9-8fr6d                 1/1     Running   0          4m17s
productpage-v1-6b746f74dc-mvl9n             1/1     Running   0          4m17s
ratings-v1-b6994bb9-zxq8n                   1/1     Running   0          4m17s
reviews-v1-545db77b95-c99dk                 1/1     Running   0          4m17s
reviews-v2-7bf8c9648f-rsndb                 1/1     Running   0          4m17s
reviews-v3-84779c7bbc-kzhwl                 1/1     Running   0          4m17s
tsb-gateway-bookinfo-73668b6aab-jygvk       1/1     Running   0          4m18s

kubectl get workspaces -A
NAMESPACE   NAME       PRIVILEGED   TENANT    AGE
bookinfo    bookinfo                tetrate   4m20s

# Use tctl to check for correct WS status. You can use the TSB UI instead.
$ tctl x status ws bookinfo
NAME        STATUS      LAST EVENT    MESSAGE
bookinfo    ACCEPTED
```

This means everything is up and running. The the bookinfo service can be
accessed on the configured hostname through the ingress gateway. 

If DNS is not configured in the cluster, or do you want to test it from your
local environment, you can run a `curl` against the productpage service via its
ingress gateway public IP like this.

```bash{promptUser: "alice"}
$ export IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ curl -H "Host: bookinfo.example.com" http://$IP/productpage
```

### Troubleshooting

Remember to bump the chart version when publishing new changes to the Chart.

If there are no changes and you want to force flux to re-run, do:

```bash{promptUser: "alice"}
$ flux reconcile helmrelease bookinfo
```

You can also check for issues in the Flux Kubernetes resources:
```bash{promptUser: "alice"}
$ flux get helmreleases -A
NAMESPACE  	NAME    	REVISION	SUSPENDED	READY	MESSAGE
flux-system	bookinfo	        	False    	False	install retries exhausted

kubectl get helmreleases -A -o yaml
...
```

If you see a `upgrade retries exhausted` message, there is a [bug
regression](https://github.com/fluxcd/helm-controller/issues/454). The workaround is
to suspend and resume the `HelmRelease`:

```bash{promptUser: "alice"}
$ flux suspend helmrelease bookinfo
$ flux resume helmrelease bookinfo
```

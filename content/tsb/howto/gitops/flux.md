---
title: "配置 Flux CD 进行 GitOps"
description: "如何配置 Flux CD 与 Helm 和 GitHub 集成，以将 TSB 应用程序部署到目标集群。"
weight: 2
---

本文档解释了如何配置 [Flux CD](https://fluxcd.io/) 与 Helm 和 GitHub 集成，以将 TSB 应用程序部署到目标集群。

{{<callout note 注意>}}
本文档假设以下情况：

- 已安装 [Flux](https://fluxcd.io/docs/installation/) 版本 2 的 CLI。
- 已安装 [Helm](https://helm.sh/docs/intro/install) 的 CLI。
- TSB 正在运行，并且已为目标集群启用了 GitOps [配置](../../../operations/features/configure-gitops)。
{{</callout>}}

## 集群设置

首先，在目标集群上使用 [GitHub 集成](https://fluxcd.io/docs/cmd/flux_bootstrap_github/) 安装 Flux。要执行此操作，请在目标集群 Kubernetes 上下文下使用以下命令。

{{<callout note 注意>}}
你将需要一个 GitHub [个人访问令牌](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)（PAT）输入以下命令。
{{</callout>}}

```bash
$ flux bootstrap github \
  --owner=your-org \
  --repository=git-ops \
  --path=./clusters/cluster-01
```

{{<callout note 注意>}}
如果你使用个人 GitHub 帐户进行测试，可以添加 `--personal --private` 标志。
{{</callout>}}

这将为名为 `cluster-01` 的集群在名为 `git-ops` 的 GitHub 存储库的 `clusters/cluster-01/` 目录下设置 Flux 所需的配置。

{{<callout note 注意>}}
为了调试目的，在不同的 shell 中运行 `flux logs -A --follow` 命令。
{{</callout>}}

你可以运行此命令进行一般状态检查：

```bash
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

在内部，Flux 使用 [`Kustomization`](https://fluxcd.io/docs/components/kustomize/kustomization/) 与 [`GitRepository`](https://fluxcd.io/docs/components/source/gitrepositories/) 源来存储自己的资源。

你可以查询其状态：

```bash
$ flux get all
名称                	修订版本     	暂停   	已准备好  	消息
gitrepository/flux-system	main/36dff73	False    	True    	已存储的修订版本 'main/36dff739b5ae411a7b4a64010d42937bd3ae4d25'

名称                	修订版本     	暂停   	已准备好  	消息
kustomization/flux-system	main/36dff73	False    	True    	应用的修订版本：main/36dff73
```

同时，在日志中你将看到类似以下的信息：

```sh
2022-04-24T20:42:06.921Z info Kustomization/flux-system.flux-system - 服务器端应用完成
2022-04-24T22:51:30.431Z info GitRepository/flux-system.flux-system - artifact up-to-date with remote revision: 'main/36dff739b5ae411a7b4a64010d42937bd3ae4d25'
```

由于 Flux 现在正在运行，下一步是将新配置推送到 `git-ops` 存储库，以用于 `cluster-01` 集群。你可以克隆存储库并 `cd` 到 `clusters/cluster-01` 以执行下一步。

## 应用程序设置

有[几种方法](https://fluxcd.io/docs/guides/repository-structure/)可以组织你的 GitOps 存储库。在此示例中，出于简单起见，同一个存储库用于集群和应用程序配置。

本节的目标是部署[Bookinfo](https://istio.io/latest/docs/examples/bookinfo/)应用程序的 Helm 图表及其 TSB 资源。

首先，创建带有 Sidecar 注入的 `bookinfo` 命名空间：
```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

然后，在 `clusters/cluster-01/bookinfo.yaml` 中创建 [`HelmRelease`](https://fluxcd.io/docs/guides/helmreleases/) Flux 资源，该资源使用 [`GitRepository`](https://fluxcd.io/docs/components/source/gitrepositories/) 来定义 Bookinfo。

{{<callout note 注意>}}
`GitRepository` 的替代方法是 [`HelmRepository`](https://fluxcd.io/docs/components/source/helmrepositories/)，本文档未涵盖此项内容。
{{</callout>}}

如果 `bookinfo` TSB helm 图表定义存储在 `apps/bookinfo` 目录中，则在 `clusters/cluster-01/bookinfo.yaml` 中创建 `HelmRelease` 资源。

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

注意：
- `HelmRelease` 将在 `flux-system` 命名空间中创建，而 release 的 Helm 图表定义的资源将在 `bookinfo` 目标命名空间中部署。
- 由于未指定 `spec.chart.spec.version`，Flux 将使用图表的 _latest_ 版本。
- `GitRepository.name` 为 `flux-system`，因为 Flux 在内部使用此名称进行

引导。

接下来，将文件添加并推送到 git，并监视 flux 日志。你将看到类似以下的信息：

```sh
2022-04-25T08:02:37.233Z info HelmRelease/bookinfo.flux-system - 协调完成，耗时 49.382555ms，下一次运行在 1m0s 内
2022-04-25T08:02:37.980Z info HelmChart/flux-system-bookinfo.flux-system - 丢弃事件，未找到涉及对象的警报
2022-04-25T08:02:45.784Z error HelmChart/flux-system-bookinfo.flux-system - 协调停滞，无效的图表引用：stat /tmp/helmchart-flux-system-flux-system-bookinfo-4167124062/source/apps/bookinfo: 文件或目录不存在
```

这是因为 helm 图表尚未推送到 `apps/bookinfo` 目录中。

请注意，你可以使用 `kubectl` 查询资源来代替解析 flux 日志：
- `kubectl get helmreleases -A`
- `kubectl get helmcharts -A`

接下来，创建 helm 图表。创建 `apps/` 目录，进入该目录并运行：

```bash
$ helm create bookinfo
```

这将创建以下文件树：

```bash
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

然后，进入 `bookinfo/`。

为了简化起见，删除不需要的内容：

```bash
$ rm -rf values.yaml charts templates/NOTES.txt templates/*.yaml templates/tests/
```

接下来，编辑 `Chart.yaml`。最小内容如下：

```yaml
apiVersion: v2
name: bookinfo
description: TSB bookinfo Helm Chart.
type: application
version: 0.1.0
appVersion: "0.1.0"
```

接下来，在 `templates/` 目录中添加 Bookinfo 定义，从 Istio 的存储库中获取它们：

```bash
curl https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml -o bookinfo.yaml
```

一旦我们有了 bookinfo 部署，我们将在 `templates/tsb.yaml` 文件中添加 TSB 配置资源。创建 TSB 配置时，最佳实践是将它们全部放在 `List` 资源内。这将强制在将它们应用到集群时遵循严格的顺序，你将能够保证高层级 TSB 资源首先应用，不会因 [Helm 资源排序限制](https://github.com/helm/helm/issues/8439) 而遇到问题。

{{<callout note 注意>}}
在此示例中，应用程序使用入口网关，该网关将由下面的第一个资源配置进行配置。你可以在 [此处](https://docs.tetrate.io/service-bridge/1.4.x/en-us/refs/install/dataplane/v1alpha1/spec) 详细了解。
此外，请确保将 _your-org_ 和 _your-tenant_ 更改为实际值。
{{</callout>}}

```yaml
apiVersion: v1
kind: List
items:
# 创建一个作为 bookinfo 应用程序入口点的入口网关部署
- apiVersion: install.tetrate.io/v1alpha1
  kind: IngressGateway
  metadata:
    namespace: bookinfo
    name: tsb-gateway-bookinfo
  spec: {}
# 创建工作空间和网关组，捕获 bookinfo 应用程序将运行的命名空间
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
# 在应用程序入口中公开 productpage 服务
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

在推送之前，测试图表是否构建良好：

```bash
$ helm install bookinfo --dry-run .
```

它应该会将渲染的资源打印为 YAML。

现在是时候推送它们并检查 flux 日志了。

如果在集群中正确配置了 GitOps，则推送此图表将创建相应的 Kubernetes 和 TSB 资源：

```bash
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

这意味着一切都已经正常运行。你可以通过配置的主机名通过入口网关访问 bookinfo 服务。

如果集群中没有配置 DNS，或者你想要从本地环境测试它，可以通过其入口网关公共 IP 对 productpage 服务运行 `curl`，如下所示。

```bash
$ export IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ curl -H "Host: bookinfo.example.com" http://$IP/productpage
```

### 故障排除

请记住，在发布 Chart 的新更改时要提高 Chart 版本。

如果没有更改，但你想强制 flux 重新运行，可以执行以下操作：

```bash
$ flux reconcile helmrelease bookinfo
```

你还可以检查 Flux Kubernetes 资源中的问题：

```bash
$ flux get helmreleases -A
NAMESPACE  	NAME    	REVISION	SUSPENDED	READY	MESSAGE
flux-system	bookinfo	        	False    	False	install retries exhausted

kubectl get helmreleases -A -o yaml
...
```

如果看到 `upgrade retries exhausted` 消息，那么有一个 [bug 回归](https://github.com/fluxcd/helm-controller/issues/454)。解决方法是暂停并恢复 `HelmRelease`：

```bash
$ flux suspend helmrelease bookinfo
$ flux resume helmrelease bookinfo
```
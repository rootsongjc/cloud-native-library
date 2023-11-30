---
title: Istio 隔离边界
description: 如何使用隔离边界部署或升级多个隔离的控制平面集群
weight: 11
---

Istio 隔离边界可以在 Kubernetes 集群内或跨多个集群中运行多个由 TSB（Tetrate Service Bridge）管理的 Istio 环境。这些 Istio 环境在服务发现和配置分发方面彼此隔离。隔离边界带来了以下几个好处：

- 强大的网络隔离默认提供了在高度受管制的环境中严格且易于演示的安全性。
- 在集群内运行不同的 Istio 版本允许你在同一集群中支持传统和现代应用程序。
- 金丝雀发布提供了在测试和部署 TSB 升级时的灵活性。

## 安装

{{<callout note 升级>}}
要从非修订的控制平面升级到修订的控制平面，请按照 [非修订版到修订版的升级](../upgrades/non-revisioned-to-revisioned) 中提到的步骤进行操作。
{{</callout>}}

{{<callout note OpenShift>}}
如果你使用 OpenShift，请将以下 `kubectl` 命令替换为 `oc`。
{{</callout>}}

对于全新安装，你可以按照使用 [tctl](../../setup/self-managed/onboarding-clusters) 或 [helm](../../setup/helm/controlplane) 来加入控制平面集群的标准步骤，以及以下更改进行操作：

1. 通过将 `ISTIO_ISOLATION_BOUNDARIES` 设置为 `true` 在 TSB 控制平面 Operator 中启用隔离边界。
2. 在 `ControlPlane` CR 或控制平面 Helm 值中添加隔离边界定义。

在以下示例中，你将使用 Helm 启用隔离边界来加入一个集群。

### 使用 Helm 安装

按照 [使用 Helm 安装控制平面](../../setup/helm/controlplane) 中的说明，使用以下 Helm 值来启用 Istio 隔离边界。

```yaml
operator:
  deployment:
    env:
      - name: ISTIO_ISOLATION_BOUNDARIES
        value: "true"

spec:
  managementPlane:
    clusterName: <cluster-name-in-tsb>
    host: <tsb-address>
    port: <tsb-port>
  telemetryStore:
    elastic:
      host: <tsb-address>
      port: <tsb-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
      - name: qa
        revisions:
        - name: qa-stable

secrets:
  clusterServiceAccount:
    clusterFQN: organizations/jupiter/clusters/<cluster-name-in-tsb>
    JWK: '$JWK'
```

安装步骤完成后，请查看 `istio-system` 命名空间中的 `deployments`、`configmaps` 和 `webhooks`。所有属于修订的 Istio 控制平面的资源都将在名称中具有 `revisions.name` 作为后缀。这些资源将存在于配置在 `isolationBoundaries` 下的每个修订中。

控制平面 Operator 会验证跨隔离边界的修订名称是否唯一。此修订名称值将用于配置修订的命名空间并启动修订的数据平面网关。

```bash
kubectl get deployment -n istio-system | grep stable
```
```
# 输出
istio-operator-dev-stable             1/1     1            1           2d1h
istio-operator-qa-stable              1/1     1            1           45h
istiod-dev-stable                     1/1     1            1           2d1h
istiod-qa-stable                      1/1     1            1           45h
```

```bash
kubectl get configmap -n istio-system | grep stable
```
```
# 输出
istio-dev-stable                      2      2d1h
istio-qa-stable                       2      45h
istio-sidecar-injector-dev-stable     2      2d1h
istio-sidecar-injector-qa-stable      2      45h
```

### 使用 tctl 安装

如果你更喜欢使用 [tctl 安装](../self-managed/onboarding-clusters)，你可以使用以下命令生成启用 Istio 隔离边界的集群 Operator。

```bash
tctl install manifest cluster-operators \
  --registry <registry-location> \
  --set "operator.deployment.env[0].name=ISTIO_ISOLATION_BOUNDARIES" \
  --set "operator.deployment.env[0].value=true" > clusteroperators.yaml
```

然后，在你的 `ControlPlane` CR 或 Helm 值中使用以下方式更新 `xcp` 组件与 `isolationBoundaries`：

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
      - name: qa
        revisions:
        - name: qa-stable
```

无论你选择哪种安装方式，使用隔离边界的示例都是相同的。

### 在修订中指定 TSB 版本

Istio 隔离边界还提供了一种控制用于部署控制平面组件和数据平面代理的 Istio 版本的方式。可以在隔离边界配置中指定如下：

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
          istio:
            tsbVersion: 1.6.1
      - name: qa
        revisions:
        - name: qa-stable
          istio:
            tsbVersion: 1.6.0
```

使用这些配置，会部署两个修订的控制平面，使用相应的 TSB 发布的 Istio 镜像。
在单个隔离边界中具有多个修订有助于从一个 `tsbVersion` 升级到另一个 `tsbVersion` 中的特定隔离边界的工作负载。有关更多详细信息，请参阅 [已修订版本间的升级](../upgrades/revisioned-to-revisioned)。

如果将 `tsbVersion` 字段留空，则 `ControlPlane` 资源将默认为当前 TSB 发布的版本。

## 使用隔离边界和修订

### 应用部署

现在可以在具有修订标签的适当命名空间中部署工作负载。修订标签 `istio.io/rev` 确定了代理用于连接服务发现和 xDS 更新的修订控制平面。确保如下配置工作负载命名空间：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: dev-stable
  name: dev-bookinfo
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: qa-stable
  name: qa-bookinfo
```

这些命名空间中的应用程序 Pod 将被注入 Istio 代理配置，使它们能够连接到相应的修订 Istio 控制平面。

### VM 工作负载载入

{{<callout note 单一隔离边界>}}
[工作负载载入](../workload-onboarding/guides) 仅支持单一隔离边界。多个隔离边界的支持将在后续版本中提供。
{{</callout>}}

默认情况下，工作负载入网将使用非修订的 Istio 控制平面。要使用修订的控制平面，你需要使用 [修订链接](../workload-onboarding/guides/setup) 从 TSB 工作负载入网存储库下载 Istio Sidecar。

你还需要在 VM 的 `/etc/onboarding-agent/agent.config.yaml` 中更新 [代理配置](../../refs/onboarding/config/agent/v1alpha1/agent-configuration) 以添加修订值。

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
sidecar:
  istio:
    revision: dev-stable
```

然后重新启动入网代理。

```bash
systemctl restart onboarding-agent
```

如果你使用 cloud-init 来配置 VM，请在 cloud-init 文件中添加上述 `AgentConfiguration`。由于文件 `/etc/onboarding-agent/agent.config.yaml` 可能提前创建，因此对于基于 Debian 的操作系统，需要在非交互式安装时安装入网代理时传递 `-o Dpkg::Options::="--force-confold"`。

```bash
sudo apt-get install -y -o Dpkg::Options::="--force-confold" ./onboarding-agent.deb
```

### 工作区配置

可以通过指定隔离边界名称来配置每个工作区，如下所示：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: qa-ws
spec:
  isolationBoundary: qa
  namespaceSelector:
    names:
      - "*/qa-bookinfo"
```

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: dev-ws
spec:
  isolationBoundary: dev
  namespaceSelector:
    names:
      - "*/dev-bookinfo"
```

{{<callout note "设置">}}
在 Brownfiled 设置中，现有的工作区将不会配置为任何特定的隔离边界。在这种情况下，如果启用并配置了 Istio 隔离边界，则工作区将视为属于一个名为 "global" 的隔离边界。如果未在 `ControlPlane` CR 中配置此 "global" 隔离边界，则工作区将不属于任何隔离边界。因此，建议为未在其规范中指定任何隔离边界的工作区创建一个名为 "global" 的备用隔离边界。

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
          - name: default
```
{{</callout>}}

### 网关部署

对于每个网关（入口/出口/Tier1）资源，必须设置属于所需隔离边界的 `revision`。

例如，在你的入口网关部署中：

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-dev-bookinfo
  namespace: dev-bookinfo
spec:
  revision: dev-stable         # 修订值
```

应用后，这将导致 **修订的** 网关部署。

### Istio 隔离

在单个/多个集群中设置多个隔离边界允许用户运行在服务发现方面分隔的多个网格环境。这意味着一个隔离边界中的服务仅对相同隔离边界中的客户端可发现，从而允许流量流向相同隔离边界中的服务。通过隔离边界分离的服务将无法发现彼此，从而导致不跨边界流量。

作为一个简单的示例，考虑以下隔离边界配置：

```yaml
...
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: dev
        revisions:
        - name: dev-stable
        revisions:
       

 - name: dev-testing
      - name: qa
        revisions:
        - name: qa-stable
```

这对应于三个单独的命名空间 `dev-bookinfo`、`dev-bookinfo-testing` 和 `qa-bookinfo`，适当附加修订标签。

```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: dev-testing
  name: dev-bookinfo-testing
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: dev-stable
  name: dev-bookinfo
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: qa-stable
  name: qa-bookinfo
```

请注意，命名空间 `dev-bookinfo` 和 `dev-bookinfo-testing` 属于同一个隔离边界 `dev`，而命名空间 `qa-bookinfo` 属于隔离边界 `qa`。

该配置将对集群产生以下影响：

1. 命名空间 `dev-bookinfo` 中的服务将被命名空间 `dev-bookinfo` 和 `dev-bookinfo-testing` 中运行的代理发现。这是因为命名空间 `dev-bookinfo` 和 `dev-bookinfo-testing` 都属于同一个隔离边界。

2. 命名空间 `dev-bookinfo` 中的服务将不会被命名空间 `qa-bookinfo` 中运行的代理发现。这是因为命名空间 `dev-bookinfo` 和 `qa-bookinfo` 属于不同的隔离边界。

以及其他命名空间的情况类似。

### 严格隔离

如果一个来自一个隔离边界的服务尝试与另一个隔离边界的服务通信，则 "客户端" 端代理将处理出站流量以确定是否流向网格外部。默认情况下，允许此流量，但可以通过在 `IstioOperator` 资源 mesh 配置中使用 `outboundTrafficPolicy` 来限制它。
默认情况下，这个 `outboundTrafficPolicy` 的值设置为

```yaml
outboundTrafficPolicy:
  mode: ALLOW_ANY
```

为了限制跨隔离边界流量，你可以将 `.outboundTrafficPolicy.mode` 设置为 `REGISTRY_ONLY`。

- 首先列出 `istio-system` 命名空间中的 `IstioOperator` 资源。

```
kubectl get iop -n istio-system | grep xcp-iop
```

```
# 输出
xcp-iop-dev-stable               stable   HEALTHY     25h
xcp-iop-dev-testing              stable   HEALTHY     25h
xcp-iop-qa-stable                stable   HEALTHY     25h
```

- 选择要设置策略配置的 `IstioOperator` 资源名称。我们将使用上面的 TSB 控制平面 Helm 值进行修订，以及以下用于 `istio` 组件的覆盖：

```yaml
spec:
  ...
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: xcp-iop-dev-stable
          patches:
          - path: spec.meshConfig.outboundTrafficPolicy
            value:
              mode: REGISTRY_ONLY
```

可以通过附加的方式以类似的方式为其他 `IstioOperator` 执行此操作。

## 故障排除

1. 查找位于 `istio-system` 命名空间中与 TSB `IngressGateway`、`EgressGateway`、`Tier1Gateway` 资源相对应的 `ingressdeployment`、`egressdeployment`、`tier1deployment` 资源。

```
kubectl get ingressdeployment -n istio-system
```

```
# 输出
NAME                       AGE
tsb-gateway-dev-bookinfo   3h10min
```

如果缺少这些资源，则 TSB 控制平面运算符未协调 TSB 网关资源到相应的 XCP 资源。首先，重新验证 TSB 控制平面运算符和网关资源之间的修订匹配。接下来，Operator 日志应该提供一些线索。

2. 查找位于 `istio-system` 命名空间中的相应 `IstioOperator` 资源。例如：

```
kubectl get iop -n istio-system | grep dev-stable
```

```
# 输出
xcp-iop-dev-stable               dev-stable   HEALTHY     25h
xcpgw-tsb-dev-gateway-bookinfo   dev-stable   HEALTHY     3h14min
```

如果缺少这些资源，则 `xcp-operator-edge` 日志应该提供一些线索。

3. 如果上述两点都没问题，网关部署/服务仍然没有部署或部署配置与 `IstioOperator` 资源中配置的不符，则 Istio 运算符部署日志应该提供一些线索。

4. 要调试 Istio 代理的服务发现以及服务之间的流量，以下 `istioctl` 命令非常有用：

```
istioctl pc endpoints -n <namespace> deploy/<deployment-name>
```

```
# 输出
ENDPOINT                                                STATUS      OUTLIER CHECK     CLUSTER
10.20.0.36:8090                                         HEALTHY     OK                outbound|80||echo.echo.svc.cluster.local
10.255.20.128:15443                                     HEALTHY     OK                outbound|80||echo.tetrate.io
...
127.0.0.1:15000                                         HEALTHY     OK                prometheus_stats
127.0.0.1:15020                                         HEALTHY     OK                agent
unix://./etc/istio/proxy/XDS                            HEALTHY     OK                xds-grpc
unix://./var/run/secrets/workload-spiffe-uds/socket     HEALTHY     OK                sds-grpc
```

和

```
istioctl pc routes -n <namespace> deploy/<deployment-name>
```

```
# 输出
NAME                                                        DOMAINS                                                         MATCH                  VIRTUAL SERVICE
80                                                          echo, echo.echo + 1 more...

                                   *                       dev/echo.echo
```

你可以根据特定的部署和命名空间替换 `<namespace>` 和 `<deployment-name>`。

这将显示特定部署的终结点和路由，以及它们的状态。你可以查看与特定服务和端点之间的流量匹配的路由规则。这些命令可帮助你排除服务发现问题或配置问题。

### 注意事项

- 隔离边界的最大数量由 TSB 控制平面配置决定。有关详细信息，请参阅控制平面配置。
- 修订的控制平面的可用性与非修订的控制平面一样，通过删除对应的 TSB 控制平面资源来禁用。
- 默认情况下，每个 Istio 控制平面版本都使用相同的内部 CA。将 Istio 控制平面升级到新版本时，可能会创建新的 CA。如果你有运行中的 mTLS 流量，请确保进行测试以验证在 CA 更改后是否仍然能够正常工作。有关详细信息，请参阅修订到修订的升级。
- 如果你想跨隔离边界运行 mTLS 流量，则需要确保 TSB 控制平面支持跨隔离边界的 mTLS 流量。这需要将跨边界服务的根证书添加到 TSB 控制平面的根证书存储库中。
- 如果你要在生产环境中使用 Istio 隔离边界，请在生产环境之前仔细测试你的配置。Istio 隔离边界是一个强大的功能，但也复杂，需要精心设计和配置以满足你的需求。
- 如果你使用的是 Istio 1.9.0 版本或更高版本，请注意 Istio 资源中的一些字段名称可能发生了变化。请查看 Istio 的官方文档，以了解与你使用的 Istio 版本相关的详细信息。

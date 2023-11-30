---
title: 控制对外部服务的访问
description: "使用 Egress Gateway 配置对外部服务的访问。"
weight: 10
---

Egress Gateway 充当流出网格的流量网关。用户可以定义允许通过网关向外部服务发送流量的服务。

目前只能发送外部的 HTTPS 流量。但是，原始的出站请求应使用 HTTP。这些出站 HTTP 请求会转换为 HTTPS 请求并发送到外部服务。例如，从通过 Egress Gateway 经过的服务发送到 `http://tetrate.io` 的请求会被转换为对 `https://tetrate.io` 的请求，并代表原始服务进行代理。目前不支持最终需要是 HTTP 的请求。例如，如果你的最终目的地是 `http://tetrate.io`，则无法使用 Egress Gateway。

本文将描述如何配置 Egress Gateway，允许服务只能向特定服务发送出站请求。以下图示显示了在使用 Egress Gateway 时的请求和响应流程：

![Egress Gateway 流程](../../../assets/howto/egress-gateway-flow.png)

在开始之前，请确保你已经：
- 熟悉 [TSB 概念](../../../concepts/)
- 安装了 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装。
- 完成了 [TSB 快速入门](../../../quickstart)。本文假定你已经创建了租户，并熟悉 Workspace 和 Config Group。还需要将 tctl 配置到你的 TSB 环境中。

请注意，在以下示例中，你将在使用 TSB 演示安装创建的演示集群中部署 Egress Gateway。如果你使用其他集群，请相应更改示例中的集群名称。

## 部署 Sleep 服务

在本示例中，你将使用两个 `sleep` 服务，它们各自位于不同的命名空间中。

创建命名空间 `sleep-one` 和 `sleep-two`：

```bash
kubectl create namespace sleep-one
kubectl create namespace sleep-two
```

然后按照["在 TSB 中安装 `sleep` Workload"](../../../reference/samples/sleep-service)文档中的说明，在 `demo` 集群中安装两个 `sleep` 服务。将服务 `sleep-one` 安装在命名空间 `sleep-one` 中，将服务 `sleep-two` 安装在命名空间 `sleep-two` 中。

你**无需**创建 Workspace，因为你将在本示例中稍后创建。

## 为 Sleep 服务创建 Workspace 和 Traffic Group

你将需要一个 Traffic Group 来与稍后创建的 Egress Gateway 关联。由于 Traffic Group 属于 Workspace，你还需要创建一个 Workspace。

创建一个名为 `sleep-workspace.yaml` 的文件，其内容如下。根据需要替换 `cluster`、`organization` 和 `tenant` 的值。在演示安装中，你可以为 `cluster` 使用值 `demo`，对于 `organization` 和 `tenant`，都可以使用值 `tetrate`。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: sleep
spec:
  displayName: Sleep Workspace
  namespaceSelector:
    names:
      - "<cluster>/sleep-one"
      - "<cluster>/sleep-two"
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: sleep
  name: sleep-tg
spec:
  displayName: Sleep Traffic
  namespaceSelector:
    names:
      - "<cluster>/sleep-one"
      - "<cluster>/sleep-two"
  configMode: BRIDGED
```

使用以下命令应用：

```bash
tctl -f sleep-workspace.yaml
```

## 部署 Egress Gateway

### 创建 Egress Gateway 命名空间

通常，Egress Gateway 由与开发应用程序不同的团队管理（在本例中是 `sleep` 服务），以避免混淆所有权。

在本示例中，我们创建一个名为 `egress` 的单独命名空间来管理 Egress Gateway。执行以下命令创建新命名空间：

```bash
kubectl create namespace egress
```

### 部署 Egress Gateway

创建一个名为 `egress-deploy.yaml` 的文件，其内容如下：

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: EgressGateway
metadata:
  name: cluster-egress
  namespace: egress
spec:
  kubeSpec:
    service:
      type: NodePort  
```

使用 kubectl 应用：

```bash
kubectl apply -f egress-deploy.yaml
```

### 为 Egress Gateway 创建 Workspace 和 Gateway Group

你还需要为刚刚创建的 Egress Gateway 创建一个 Workspace 和 Gateway Group。

创建一个名为 `egress-workspace.yaml` 的文件，其内容如下。根据需要替换 `cluster`、`organization` 和 `tenant` 的值。在演示安装中，你可以为 `cluster` 使用值 `demo`，对于 `organization` 和 `tenant`，都可以使用值 `tetrate`。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: egress
spec:
  displayName: Egress Workspace
  namespaceSelector:
    names:
      - "<cluster>/egress"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: egress
  name: egress-gw
spec:
  displayName: Egress Gateway
  namespaceSelector:
    names:
      - "<cluster>/egress"
  configMode: BRIDGED
```

使用 tctl 应用：

```bash
tctl apply -f egress-workspace.yaml
```

## 配置 Egress Gateway

在本示例中，你将对两个 `sleep` 服务应用不同的配置。

`sleep-one` 将被配置为可以访问所有外部 URL，但 `sleep-two` 只允许访问单

一目标（在此示例中为 "edition.cnn.com"）。

创建一个名为 `egress-config.yaml` 的文件，其内容如下。根据需要替换 `organization` 和 `tenant` 的值。在演示安装中，你可以为 `organization` 和 `tenant` 使用值 `tetrate`。

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: EgressGateway
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: egress
  group: egress-gw
  name: cluster-egress 
spec:
  workloadSelector:
    namespace: egress 
    labels:
      app: cluster-egress
  authorization:
    - from:
        mode: CUSTOM
        serviceAccounts: ["sleep-one/sleep"]
      to: ["*"]
    - from:
        mode: CUSTOM
        serviceAccounts: ["sleep-two/sleep"]
      to: ["edition.cnn.com"]
```

使用 tctl 应用：

```bash
tctl apply -f egress-config.yaml
```

## 创建 TrafficSettings 以使用 Egress Gateway

最后，创建 TrafficSettings，将服务关联到 Traffic Group，并与刚刚创建的 Egress Gateway 关联。

创建一个名为 `sleep-traffic-setting-egress.yaml` 的文件，其内容如下。根据需要替换 `organization` 和 `tenant` 的值。在演示安装中，你可以为 `organization` 和 `tenant` 使用值 `tetrate`。

`host` 值的格式为 `<namespace>/<fqdn>`。`fqdn` 值是从前面步骤中指定的 `namespace` 和 `metadata.name` 值派生的：

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: sleep
  group: sleep-tg
  name: sleep-traffic-settings
spec:
  egress:
    host: egress/cluster-egress.egress.svc.cluster.local
```

使用 tctl 应用：

```bash
tctl apply -f sleep-traffic-setting-egress.yaml
```

## 测试

要测试 Egress Gateway 是否正常工作，你将从 `sleep` 服务发送请求到外部服务。

为此，你需要找出 `sleep-one` 和 `sleep-two` 的 Pod 名称。执行以下命令查找 Pod 名称：

```bash
export SLEEP_ONE_POD=$(kubectl get pod -n sleep-one -l app=sleep -o jsonpath='{.items[*].metadata.name}')
export SLEEP_TWO_POD=$(kubectl get pod -n sleep-two -l app=sleep -o jsonpath='{.items[*].metadata.name}')
```

对 `sleep-one` 执行以下命令。由于你已经配置了 Egress Gateway，使得 `sleep-one` 允许访问所有外部服务，因此以下命令应该都显示 "200"：

```bash
kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://twitter.com \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"

kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://github.com \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"

kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://edition.cnn.com \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"

kubectl exec ${SLEEP_ONE_POD} -n sleep-one -c sleep -- \
  curl http://httpbin.org \
    -s \
    -o /dev/null \
    -L \
    -w "%{http_code}\n"
```

对 `sleep-two` 执行相同操作，将 `SLEEP_ONE_POD` 替换为 `SLEEP_TWO_POD`，将 `sleep-one` 替换为 `sleep-two`。这次，只有对 edition.cnn.com 的请求应该显示 "200"，所有其他请求应该显示 "403"。

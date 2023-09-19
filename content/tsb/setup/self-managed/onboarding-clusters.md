---
title: 加入集群
description: 在 Kubernetes 上部署 Istio 控制平面并将其连接到 TSB。
weight: 3
---

本页介绍如何将 Kubernetes 集群加入现有的 Tetrate Service Bridge（TSB）管理平面。

在开始之前，请确保你已经完成以下操作：

- 检查 [要求](../../requirements-and-download)
- [安装 TSB 管理平面](../management-plane-installation) 或 [演示安装](../demo-installation)
- 使用 tctl 登录管理平面（[tctl 连接](../../tctl-connect)）
- 检查 [TSB 控制平面组件](../../components#control-plane)

{{<callout note "隔离边界">}}
TSB 1.6 引入了隔离边界，允许你在 Kubernetes 集群内或跨多个集群中拥有多个 TSB 管理的 Istio 环境。隔离边界的一个好处是你可以执行控制平面的金丝雀升级。

要启用隔离边界，你必须使用环境变量 `ISTIO_ISOLATION_BOUNDARIES=true` 更新操作员部署，并在控制平面 CR 中包含 `isolationBoundaries` 字段。
有关更多信息，请参阅 [隔离边界](../../isolation-boundaries)。
{{</callout>}}

## 创建集群对象

要为集群创建正确的凭据，以便与管理平面通信，你需要使用管理平面 API 创建一个集群对象。

根据你的需求调整以下 `yaml` 对象，并保存到名为 `new-cluster.yaml` 的文件中。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: <cluster-name-in-tsb>
  organization: <organization-name>
spec: {}
```

{{<callout note "TSB 中的集群名称">}}
&lt;cluster-name-in-tsb&gt; 是 TSB 中你集群的指定名称。你将在 TSB API 中使用此名称，例如在工作区和配置组中的命名空间选择器以及创建以下的 `ControlPlane` CR 时使用。此名称必须唯一。
{{</callout>}}

有关可配置字段的详细信息，请参阅 [Cluster](../../../refs/tsb/v2/cluster) 对象的参考文档。

要在管理平面上创建集群对象，请使用 `tctl` 来应用包含集群详细信息的 `yaml` 文件。

```bash
tctl apply -f new-cluster.yaml
```

## 部署 Operator

接下来，你需要在集群中安装必要的组件，以加入集群并将其连接到管理平面。

你必须部署两个运营商。首先是控制平面运营商，负责管理 Istio、SkyWalking 和其他各种组件。其次是数据平面运营商，负责管理网关。

```bash
tctl install manifest cluster-operators \
    --registry <registry-location> > clusteroperators.yaml
```

**标准**

`install manifest cluster-operators` 命令将输出所需运营商的 Kubernetes 清单。然后，我们可以将其添加到源代码控制或应用到集群中：

```bash
kubectl apply -f clusteroperators.yaml
```

**OpenShift**

`install manifest cluster-operators` 命令将输出所需运营商的 Kubernetes 清单。然后，我们可以将其添加到源代码控制或应用到集群中：

```bash
oc apply -f clusteroperators.yaml
```

{{<callout note "注意">}}
对于下面的 [配置密钥](#configuring-secrets) 和 [控制平面安装](#control-plane-installation) 步骤，你必须为每个集群单独创建密钥和自定义资源的 YAML 文件。
换句话说，对每个集群重复这些步骤，并确保传递上面设置的 `<cluster-name-in-tsb>` 值，然后将两个 YAML 文件应用到正确的集群。
{{</callout>}}

## 配置密钥

控制平面需要密钥以便与管理平面进行身份验证。这些包括服务帐户密钥、Elasticsearch 凭据，以及如果使用自签名证书进行管理平面、XCP 或 Elasticsearch 的 CA 捆绑包。以下是你需要创建的一些密钥的列表。

| 密钥名称                  | 描述                                                         |
| ------------------------- | ------------------------------------------------------------ |
| `elastic-credentials`     | Elasticsearch 用户名和密码。                                 |
| `es-certs`                | 当 Elasticsearch 配置为呈现自签名证书时，用于验证 Elasticsearch 连接的 CA 证书。 |
| `redis-credentials`       | 包含：<br />&ensp;1. Redis 密码。<br />&ensp;2. 使用 TLS 的标志。<br />&ensp;3. 当 Postgres 配置为呈现自签名证书时，用于验证 Redis 连接的 CA 证书。<br />&ensp;4. 如果 Redis 配置了互联 TLS，则包含客户端证书和私钥。 |
| `xcp-central-ca-bundle`   | 用于验证由 XCP Central 呈现的证书的 CA 捆绑包。              |
| `mp-certs`                | 用于验证管理平面 API 的 TSB 管理平面证书，如果管理平面配置为呈现自签名证书，则为 CA 证书。这是用于签署前端 envoy TLS 证书的 CA。 |
| `cluster-service-account` | 用于集群到控制平面之间的身份验证的服务帐户密钥。         |
| `central-cert`        | 用于签署前端 envoy TLS 证书的 CA 证书。                 |
| `edgectl-cluster`     | 包含：<br />&ensp;1. 前端 envoy 的 TLS 证书和密钥。<br />&ensp;2. 用于验证和管理各种组件连接的 CA 证书。            |

请按照以下步骤为集群创建密钥：

1. 使用以下命令创建密钥文件，如 `cluster-secrets.yaml`：

```bash
tctl install secrets cluster-secrets > cluster-secrets.yaml
```

2. 使用文本编辑器打开 `cluster-secrets.yaml` 文件，将以下字段替换为集群的实际值：

- `cluster_name`: 替换为集群名称。
- `tsb_operator_namespace`: 替换为 Istio 运营商的命名空间。
- `tsb_control_plane_namespace`: 替换为 TSB 控制平面的命名空间。
- `elastic_username` 和 `elastic_password`: 替换为 Elasticsearch 的用户名和密码。
- `redis_password`: 替换为 Redis 的密码。
- `xcp_central_ca_bundle`: 如果使用自签名证书，将其替换为 XCP Central 的 CA 捆绑包。
- `mp_certs_ca_bundle`: 如果管理平面使用自签名证书，将其替换为管理平面的 CA 捆绑包。

以下是示例 `cluster-secrets.yaml` 文件的一部分，其中包含需要替换的字段示例：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: TSB
metadata:
  name: cluster-secrets
  organization: <organization-name>
spec:
  cluster_name: <cluster-name-in-tsb>
  tsb_operator_namespace: tsb-operator
  tsb_control_plane_namespace: tetrate-system
  secrets:
    elastic_username: <elasticsearch-username>
    elastic_password: <elasticsearch-password>
    redis_password: <redis-password>
    xcp_central_ca_bundle: <xcp-central-ca-bundle>
    mp_certs_ca_bundle: <mp-certs-ca-bundle>
```

3. 使用以下命令应用密钥文件：

```bash
kubectl apply -f cluster-secrets.yaml
```

4. 在完成上述步骤后，集群应配置好密钥并准备好连接到管理平面。

## 安装控制平面

现在，你可以使用 tctl 来安装控制平面。请将以下命令中的 `<cluster-name-in-tsb>` 替换为集群的实际名称：

```bash
tctl install control-plane \
    --cluster-name <cluster-name-in-tsb> \
    --registry <registry-location> > controlplane.yaml
```

接下来，使用以下命令将控制平面清单应用到集群中：

```bash
kubectl apply -f controlplane.yaml
```

这将在集群中安装 Istio 和相关组件，并将其连接到管理平面。完成后，你的 Kubernetes 集群将成功加入 Tetrate Service Bridge 环境。

## 后续步骤

一旦集群成功加入 TSB，你可以继续执行其他操作，例如：

- [为应用程序配置网关](../../gateway-configuration)。
- [为应用程序添加流量管理规则](../../traffic-management)。
- [监视和跟踪应用程序](../../observability)。
- [在多个集群之间配置服务网格](../../multicluster)。

这些操作将帮助你在 Tetrate Service Bridge 中有效地管理和操作微服务应用程序。
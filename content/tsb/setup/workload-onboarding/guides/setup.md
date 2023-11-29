---
title: 设置工作负载载入
description: 如何设置工作负载载入。
weight: 2
---

## 步骤

1. 启用工作负载载入
2. 创建 WorkloadGroup
3. 允许工作负载加入 WorkloadGroup
4. 创建 Sidecar 配置
5. 在 VM 上安装工作负载载入代理

## 启用工作负载载入

要在给定的 Kubernetes 集群中启用工作负载载入，你需要编辑 TSB [ControlPlane](../../../../refs/install/controlplane/v1alpha1/spec) 资源或 Helm 配置，如下所示：

```yaml
spec:
  ...
  meshExpansion:
    onboarding:                                           # (1) REQUIRED
      endpoint:
        hosts:
        - <onboarding-endpoint-dns-name>                  # (2) REQUIRED
        secretName: <onboarding-endpoint-tls-cert>        # (3) REQUIRED
      tokenIssuer:
        jwt:
          expiration: <onboarding-token-expiration-time>  # (4) OPTIONAL
      localRepository: {}                                 # (5) OPTIONAL
```

然后：

1. 要在给定的 Kubernetes 集群中启用工作负载载入，你需要编辑 `spec.meshExpansion.onboarding` 部分，并为所有强制性字段提供值
2. 你必须为 Workload Onboarding Endpoint 提供一个 DNS 名称，例如 `onboarding-endpoint.your-company.corp`
3. 你必须提供保存 Workload Onboarding Endpoint 的 TLS 证书的 Kubernetes Secret 的名称
4. 你可以选择自定义载入令牌的过期时间，默认为 `1 小时`
5. 你可以选择部署 Workload Onboarding Agent 和 Istio sidecar 的 DEB/RPM 软件包的本地副本

## Workload Onboarding Endpoint

Workload Onboarding Endpoint 是各个 Workload Onboarding Agent 连接加入网格的组件。

在生产场景中，Workload Onboarding Endpoint 必须具有高可用性、稳定的地址，并对传入连接进行 TLS 强制执行。

因此，DNS 名称和 TLS 证书是启用 Workload Onboarding 的强制性参数。

### DNS 名称

你可以为 Workload Onboarding Endpoint 选择任何 DNS 名称。

该名称必须与 `istio-system` 命名空间中的 Kubernetes 服务 `vmgateway` 的地址关联。

在生产场景中，你可以使用 [`external-dns`](https://github.com/kubernetes-sigs/external-dns) 来实现这一点。

### TLS 证书

为 Workload Onboarding Endpoint 提供证书，你需要在 `istio-system` 命名空间中创建一个 TLS 类型的 Kubernetes Secret。

你有几个选项：

* 从 X509 证书和私钥创建 Kubernetes Secret（手动获取）
* 或者你可以使用 [cert-manager](https://cert-manager.io/docs/) 自动提供 TLS 证书

#### 从外部获取的 TLS 证书

为 Workload Onboarding Endpoint 提供从外部获取的 TLS 证书，请使用以下命令：

```shell
kubectl create secret tls <onboarding-endpoint-tls-cert> \
  -n istio-system \
  --cert=<path/to/cert/file> \
  --key=<path/to/key/file>
```

#### 由 `cert-manager` 提供的 TLS 证书

要自动提供 TLS 证书，你可以使用 [cert-manager](https://cert-manager.io/docs/)。

例如，你可以获取由受信任的 CA 签名的免费 TLS 证书，如 [Let's Encrypt](https://letsencrypt.org/)。

在这种情况下，你的配置将如下所示：

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <onboarding-endpoint-tls-cert>
  namespace: istio-system
spec:
  secretName: <onboarding-endpoint-tls-cert>
  duration: 2160h   # 90d
  renewBefore: 360h # 15d
  usages:
  - server auth
  dnsNames:
  - <onboarding-endpoint-dns-name>
  issuerRef:
    name: <your-issuer>
    kind: ClusterIssuer
```

有关更多详细信息，请参阅 [cert-manager](https://cert-manager.io/docs/) 文档。

## Workload Onboarding 令牌

Workload Onboarding 令牌代表将工作负载引入服务网格的临时授权。

在验证由 Workload Onboarding Agent 提交的平

台特定凭据后（例如工作负载所在的 VM 的凭据），Workload Onboarding Endpoint 会发放 Workload Onboarding 令牌。

Workload Onboarding 令牌用作 Workload Onboarding Agent 向 Workload Onboarding Endpoint 发送的后续请求的会话令牌，以提高身份验证和授权的效率。

默认情况下，Workload Onboarding 令牌的有效期为 `1 小时`。

用户可能会选择为 Workload Onboarding 令牌选择自定义过期时间，出于多种原因，例如：

* 缩短过期时间以满足组织内部制定的更严格的安全策略
* 延长过期时间以降低频繁令牌续订导致的负载

## 本地仓库

为了方便起见，可以在其网络内托管 Workload Onboarding Agent 和 Istio sidecar 的 DEB/RPM 软件包的本地副本。

一旦启用本地仓库，用户将能够从 `https://<onboarding-endpoint-dns-name>` 的 HTTP 服务器下载 DEB/RPM 软件包。

本地仓库允许下载以下工件：

| URI                                              | 描述                                    |
| ------------------------------------------------ | --------------------------------------- |
| `/install/deb/amd64/onboarding-agent.deb`        | Workload Onboarding Agent 的 DEB 软件包 |
| `/install/deb/amd64/onboarding-agent.deb.sha256` | DEB 软件包的 SHA-256 校验和             |
| `/install/deb/amd64/istio-sidecar.deb`           | Istio sidecar 的 DEB 软件包             |
| `/install/deb/amd64/istio-sidecar.deb.sha256`    | DEB 软件包的 SHA-256 校验和             |
| `/install/rpm/amd64/onboarding-agent.rpm`        | Workload Onboarding Agent 的 RPM 软件包 |
| `/install/rpm/amd64/onboarding-agent.rpm.sha256` | RPM 软件包的 SHA-256 校验和             |
| `/install/rpm/amd64/istio-sidecar.rpm`           | Istio sidecar 的 RPM 软件包             |
| `/install/rpm/amd64/istio-sidecar.rpm.sha256`    | RPM 软件包的 SHA-256 校验和             |

## 创建 WorkloadGroup

当将运行在 Kubernetes 集群之外的工作负载引入到网格时，它被视为加入某个 [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/)。

Istio WorkloadGroup 资源保存所有加入它的工作负载共享的配置。

从某种意义上说，Istio WorkloadGroup 资源对于单个工作负载就像 Kubernetes Deployment 资源对于单个 Pod 一样。

为了能够将单个工作负载引入给定的 Kubernetes 集群，你必须首先在其中创建相应的 Istio WorkloadGroup。

例如，

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: ratings
  namespace: bookinfo
  labels:
    app: ratings
spec:
  template:                           # (1)
    labels:
      app: ratings
      class: vm
    serviceAccount: ratings-vm        # (2)
    network:        virtual-machines  # (3)
```

其中

1. 所有加入该组的工作负载都继承 `spec.template` 中指定的配置
2. 在网格内，加入网格的工作负载将具有 `spec.template.serviceAccount` 中指定的 Kubernetes 服务帐户的标识。如果未设置 `spec.template.serviceAccount`，则假定为 `"default"`（此帐户在每个 Kubernetes 命名空间中都保证存在）。
3. 如果该组中的工作负载与 Kubernetes `Pods` 没有直接的连接性，必须将 `spec.template.network` 字段设置为非空值。

## 允许工作负载加入 WorkloadGroup

在 Kubernetes 集群之外运行的工作负载除非经过明确授权，否则不能加入到 mesh 中。

为了进行载入，工作负载被视为运行在其上的主机的身份。例如，如果一个工作负载运行在 AWS EC2 实例上，它被认为具有该 AWS EC2 实例的身份。

为了允许工作负载加入特定的集群，用户必须在该集群中创建一个[载入策略](../../../../refs/onboarding/config/authorization/v1alpha1/policy)。

一个 OnboardingPolicy 是 Kubernetes 资源，授权具有特定身份的工作负载加入特定的 WorkloadGroup(s)。OnboardingPolicy 必须在适用于它的 WorkloadGroup(s) 相同的命名空间中创建。

### 示例

下面的示例允许运行在任何与给定 AWS 帐户关联的 AWS EC2 实例上的工作负载加入给定 Kubernetes 命名空间中的任何可用 WorkloadGroup：

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: 允许任何 AWS EC2 实例加入给定帐户
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        accounts:
        - '123456789012'
        - '234567890123'
        ec2: {} # 上述帐户中的任何 AWS EC2 实例
    onboardTo:
    - workloadGroupSelector: {} # 该命名空间中的任何 WorkloadGroup
```

出于安全原因，AWS 帐户必须始终明确列出。由于这从不是一个良好的实践，你将无法指定与任何帐户关联的工作负载自由加入 mesh。

尽管前面的示例可能是一个相当“宽松”的策略，但更严格的载入策略可能只允许从特定 AWS 区域和/或区域中的 AWS EC2 实例加入，带有特定 AWS IAM 角色等。它还可能只允许工作负载加入特定的 WorkloadGroups 子集。

以下是一个更严格策略的示例：

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: 允许 AWS EC2 实例的狭窄子集加入
  namespace: bookinfo
spec:
  allow:
  - workloads:
    - aws:
        partitions:
        - aws
        accounts:
        - '123456789012'
        regions:
        - us-east-2
        zones:
        - us-east-2b
        ec2:
          iamRoleNames:
          - ratings-role        # 上述分区/帐户/区域/区域中与列表中 IAM 角色之一关联的任何 AWS EC2 实例
    onboardTo:
    - workloadGroupSelector:
        matchLabels:
          app: ratings          # (1)
```

上述策略授权具有标签 `app=ratings` (1) 的工作负载加入这些 WorkloadGroup(s)。例如，以下组将匹配该策略，但如果在 `label` 字段中省略或指定不同的值，则不会匹配。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: ratings
  namespace: bookinfo
  labels:
    app: ratings 
spec:
  ...
```

## 创建 Sidecar 配置

目前，工作负载载入不支持使用 `Iptables` 进行流量重定向。因此，你需要配置 Istio Sidecar 资源，并根据需要重新配置应用程序和/或主机环境。

### 工作负载配置（入口）

确保你的工作负载（即用户应用程序）侦听 `127.0.0.1`，而不是 `0.0.0.0`。

例如，如果你的应用程序侦听 `0.0.0.0:8080`，请更改其配置，使其侦听 `127.0.0.1:8080`。

这有两个效果：首先，Istio 代理和工作负载将能够在相同的端口上侦听 — 因此，代理将能够在 `<host IP>:8080` 上侦听。其次，网格中的其他节点将无法直接连接到你的应用程序。它们将被强制经过代理，代理将流量代理到 `127.0.0.1:8080`。

### 工作负载配置（出口）

配置你的应用程序以引用依赖服务的 DNS 名称。否则，应用程序将无法充分利用网格。

具体而言，应用程序应该引用其他 Kubernetes 服务的集群本地 DNS 名称，例如 `details.bookinfo`、`details.bookinfo.svc` 或 `details.bookinfo.svc.cluster.local`。

其他网格外部的服务应该使用它们的 DNS 名称引用（例如 `example.org`）

你还需要通过编辑 VM 中的 `/etc/hosts` 文件，将你的依赖服务的 DNS 名称别名为将要使用的 egress listener 的 IP 地址。

假设你在应用程序中引用 `details.bookinfo.svc` 和 `example.org`，请编辑 `/etc/hosts` 文件，包含以下行，将 `egress listener IP 地址` 替换为适当的值：

```
<egress listner IP 地址>	details.bookinfo.svc
<egress listner IP 地址>	example.org
```

因此，当你的应用程序尝试发出对 `ratings.bookinfo.svc:8080` 或 `example.org:8080` 的请求时，你的应用程序将连接到 egress listener，该监听器将代理请求到它们各自的目的地。

{{<callout note 注意>}}
或者，你可以考虑在 `http_proxy` 环境变量中指定 Istio 代理。
{{</callout>}}

### Sidecar 资源配置

你需要在 Kubernetes 集群上创建一个 Istio Sidecar 资源。YAML 定义如下：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: bookinfo-ratings-no-iptables
  namespace: bookinfo
spec:
  workloadSelector:                  # (1)
    labels:
      app: ratings
      class: vm
  ingress:                           # (2)
  - defaultEndpoint: 127.0.0.1:8080
    port:
      name: http
      number: 8080
      protocol: HTTP
  egress:                            # (3)
  - bind: 127.0.0.2
    port:
      name: http                   # REQUIRED   
      number: 8080
      protocol: HTTP               # REQUIRED
    hosts:
    - ./*
```

第 (1) 节定义了此 sidecar 适用于的 WorkloadGroups。在此示例中，此配置适用于标签匹配为 `app: ratings` 的工作负载。此示例还指定我们仅将此应用于具有 `class: vm` 标签的工作负载，该标签旨在用于区分部署在 VM 上的工作负载和部署在 Kubernetes pod 上的工作负载。

第 (2) 节定义了 Ingress 监听器。此配置指定 Istio 代理将在 `<host IP>:8080` 上侦听，并将接收到的流量转发到 `127.0.0.1:8080`，这应该是你的应用程序将侦听的地方。

第 (3) 节定义了 Egress 监听器。此配置指定 Egress 监听器将在 `127.0.0.2:8080` 上侦听。它还指定 Egress 监听器将代理对匹配 `hosts` 列表且具有端口 `8080` 的任何服务的出站请求。

## 在 VM 上安装 Workload Onboarding Agent

你需要在要进行载入的 VM 上安装以下组件：

1. Workload Onboarding Agent
1. Istio Sidecar

根据你的偏好使用 DEB 或 RPM 包。你可以从本地存储库的以下地址下载这些包 `https://<onboarding-endpoint-dns-name>`（有关更多详细信息，请参阅“启用 Workload Onboarding”）。

如果使用基于 ARM 的 VM，请在以下示例中将 `amd64` 更改为 `arm64`。

### 安装 Workload Onboarding Agent DEB 包

运行以下命令。将 `onboarding-endpoint-dns-name` 替换为适当的值。

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/onboarding-agent.deb"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/onboarding-agent.deb.sha256"

sha256sum --check onboarding-agent.deb.sha256

sudo apt-get install -y ./onboarding-agent.deb

rm onboarding-agent.deb onboarding-agent.deb.sha256
```

### 安装 Workload Onboarding Agent RPM 包

运行以下命令。将 `onboarding-endpoint-dns-name` 替换为适当的值。

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/onboarding-agent.rpm"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/onboarding-agent.rpm.sha256"

sha256sum --check onboarding-agent.rpm.sha256

sudo yum install -y ./onboarding-agent.rpm

rm onboarding-agent.rpm onboarding-agent.rpm.sha256
```

### 安装 Istio Sidecar DEB 包

运行以下命令。将 `onboarding-endpoint-dns-name` 替换为适当的值。

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/istio-sidecar.deb"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/deb/amd64/istio-sidecar.deb.sha256"

sha256sum --check istio-sidecar.deb.sha256

sudo apt-get install -y ./istio-sidecar.deb

rm istio-sidecar.deb istio-sidecar.deb.sha256
```

### 安装 Istio Sidecar RPM 包

运行以下命令。将 `onboarding-endpoint-dns-name` 替换为适当的值。

```bash
curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/istio-sidecar.rpm"

curl -fLO "https://<onboarding-endpoint-dns-name>/install/rpm/amd64/istio-sidecar.rpm.sha256"

sha256sum --check istio-sidecar.rpm.sha256

sudo yum install -y ./istio-sidecar.rpm

rm istio-sidecar.rpm istio-sidecar.rpm.sha256
```

### 为 Revisioned Istio 安装 Istio Sidecar

如果启用了 [Istio 隔离边界](../../../isolation-boundaries)，你需要使用带有 Istio 修订版名称的包下载路径来下载 DEB 或 RPM 包。将 `<istio-revision>` 替换为你想要使用的 Istio 修订版名称。

DEB 包的修订版链接。
```
https://<onboarding-endpoint-dns-name>/install/istio-sidecar/<istio-revision>/deb/amd64/istio-sidecar.deb
```

RPM 包的修订版链接。
```
https://<onboarding-endpoint-dns-name>/install/istio-sidecar/<istio-revision>/rpm/amd64/istio-sidecar.rpm
```

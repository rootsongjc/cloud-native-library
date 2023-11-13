---
title: 使用 tctl 将虚拟机（VM）接入 TSB 服务网格
description: 将虚拟机或裸机接入 TSB 服务网格的指南。
weight: 3
---

{{<callout note 裸机服务器>}}
在本指南中，我们仅提及虚拟机（VM）。如果你想将运行在裸机服务器上的工作负载接入到 TSB 服务网格中，只需将 "VM" 替换为 "裸机" 即可。在处理它们时没有任何区别。
{{</callout>}}

## 问题定义

Istio 和底层的 Kubernetes 平台共同构建了一个封闭的生态系统，控制平面和数据平面组件紧密集成。例如，运行在每个节点上的控制平面组件创建了相互信任的关系。当新的 Pod 被调度在一个节点上运行时，该节点是一个受信任的实体，其关键资源，如 iptables，会被修改。

当一个虚拟机（VM）被引入这个生态系统时，它是一个外部实体。要成功地将一个 Istio/Kubernetes 集群扩展到一个 VM 上，必须执行以下步骤：
- 认证。VM 必须与控制平面建立一个经过认证的加密会话，证明它被允许加入集群。
- 路由。VM 必须知道在 Kubernetes 集群中定义的服务，反之亦然。如果 VM 运行一个服务，它必须对在集群内运行的 Pod 可见。

## 概述

将虚拟机（VM）接入 TSB 管理的 Istio 服务网格可以分为以下步骤：

- 使用 Istio 控制平面注册 VM 工作负载（WorkloadEntry）
- 获取用于在 VM 上运行的 Istio 代理的引导安全令牌和种子配置
- 将引导安全令牌和种子配置传输到 VM
- 在 VM 上启动 Istio 代理

为了改善 VM 接入的用户体验，TSB 提供了 `tctl` CLI，它可以自动化大部分这些任务。

在高层次上，`tctl` 旨在将 VM 接入流程简化为一个单一的命令：

```bash
tctl x sidecar-bootstrap
```

`tctl` Sidecar 引导逻辑以及将 VM 工作负载注册到服务网格的操作由 `WorkloadEntry` 资源内部的配置驱动。`tctl` Sidecar 引导允许你将 VM 接入到 Kubernetes 上的服务网格中，从而实现了对各种网络和部署方案的支持。`tctl` Sidecar 引导还允许在任何情况下、从任何上下文中（开发者机器或 CI/CD 流水线）重现 VM 接入。

## 要求

在开始之前，请确保你具备以下条件：

- TSB 版本 0.9 或以上
- 一个已接入 TSB 的 Kubernetes 集群
- 在适当的命名空间中部署了相关应用程序
- 一个已启动并准备好的虚拟机
- 最新的 `kubectl` 已准备就绪
- 最新的 Tetrate Service Bridge CLI (`tctl`) 已准备就绪

{{<callout note 不同环境之间的差异>}}
此设置指南提供了将 VM 接入的通用步骤。由于你必须处理特定的云提供商、网络、防火墙、工作负载和操作系统的组合，你需要调整这些步骤以使其适用于你的情况。在本指南中，我们将以在 Ubuntu VM 上接入 Istio Bookinfo 示例中的 Ratings 服务为例。
{{</callout>}}

## 操作步骤

### 集群网格扩展

为了允许来自 Kubernetes 环境之外的工作负载成为服务网格的一部分，你需要在集群中启用 `mesh expansion`。编辑 [`ControlPlane`](../../refs/install/controlplane/v1alpha1/spec) CR 或 Helm 值以包含 `meshExpansion` 属性，如下所示。

```yaml
spec:
  meshExpansion: {}
```

要编辑资源，请运行以下命令：

```bash
kubectl patch ControlPlane controlplane -n istio-system \
    --patch '{"spec":{"meshExpansion":{}}}' \
    --type merge
```

完成此步骤后，你可以将尽可能多的 VM 工作负载接入到该集群中。如果你有多个集群，请为需要接入 VM 的每个集群重复此步骤。

### VM 准备工作

要为接入做好 VM 的准备工作，你需要对 VM 具有 SSH 访问权限，因为你必须添加一个用户帐户并安装额外的软件。

{{<callout note 示例环境>}}
本指南将以准备一个 Ubuntu 18.04 LTS 虚拟机为例。
{{</callout>}}

首先，请确保 VM 上已安装 Docker。稍后你将安装 Istio 代理，它将在 Docker 容器中运行。使用 Docker 可以使你将代理的依赖项与操作系统安装隔离开来，同时为代理提供一个均匀的运行环境。

要在 VM 上安装 Docker，请运行：

```bash
sudo apt-get update
sudo apt-get -y install docker.io
```

要允许 `tctl` 接入你的 VM 工作负载，请创建并配置一个专用用户帐户。此用户帐户将需要权限与 Docker 守护程序进行交互，并具有 SSH 访问权限。为了启动

接入流程，`tctl` 工具将使用 SSH 连接到你的 VM。

要设置和配置用户帐户，请运行以下命令：

```bash
# 为 VM 接入创建专用用户帐户 "istio-proxy"
sudo useradd --create-home istio-proxy

# 切换到专用用户
sudo su - istio-proxy

# 为新用户帐户配置 SSH 访问
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
touch $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/authorized_keys

#
# 将你的 SSH 公钥添加到 $HOME/.ssh/authorized_keys 中
#

# 返回特权用户
exit
```

要使新用户帐户具有与 Docker 守护程序交互的权限，你必须将该帐户添加到 docker 用户组中：

```bash
sudo usermod -aG docker istio-proxy
```

为了存储接入配置，你必须设置一个目录。如果你希望使用不同的路径，请确保它反映在稍后将配置的 `WorkloadEntry` 资源中。

```bash
sudo mkdir -p /etc/istio-proxy
sudo chmod  775 /etc/istio-proxy
sudo chown istio-proxy:istio-proxy /etc/istio-proxy
```

如果你的工作负载尚未运行，请立即启动它。在我们的示例中，我们将运行 Istio Bookinfo 示例中的 Ratings 服务。此示例将在 Docker 中运行，但并非必须如此。你的工作负载可以作为操作系统的常规进程运行。

```bash
sudo docker run -d \
    --name ratings \
    -p 127.0.0.1:9080:9080 \
    docker.io/istio/examples-bookinfo-ratings-v1:1.16.2
```

### 配置防火墙

要允许 VM 加入服务网格，必须在 VM 和 Kubernetes 集群网络端之间建立 IP（L3）连接。你可能需要在 Kubernetes 和 VM 网络端配置防火墙，以允许在各种用于流量的 TCP 端口之间进行通信。

#### Kubernetes 和 VM 在同一网络上（或互通的网络）

由于所有工作负载具有直接的 IP 连通性，因此 VM IP 与 Pod IP 之间的流量不会使用 VM 网关。

在此情况下，你必须：

- 允许从 VM IP 到 Pod IPs 的整个 TCP 端口范围的入站流量
- 允许从 Pod IPs 到 VM IP 的一组相关的 TCP 端口的入站流量

#### Kubernetes 和 VM 在不同的网络中

当跨越 Kubernetes 和 VM 的工作负载没有直接的 IP 连通性时，流量必须通过 VM 网关传递。

在这种网络隔离的情况下，Kubernetes 中 VM 网关的以下 TCP 端口必须对 VM 可用：

- 15012（控制平面 xDS 流量）
- 15443（数据平面入站流量）
- 9411（Sidecar 跟踪数据入站）
- 11800（Sidecar 访问日志入站）

{{<callout note "GKE 和 EKS">}}
在 GKE 和 EKS 上，这些端口将自动允许传入流量。
{{</callout>}}

你需要打开用于从 Kubernetes 集群到 VM 工作负载的流量的端口取决于你将在 [Sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/#Sidecar) 资源中配置的代理侦听端口。在本例中，我们使用端口 9080。在这种情况下，我们需要允许从 Kubernetes 到 VM 的 TCP 流量使用端口 9080。

### 创建 WorkloadEntry

[WorkloadEntry](https://istio.io/latest/docs/reference/config/networking/workload-entry/) 资源记录了运行在 VM 上的工作负载的信息，这将允许你使用可验证的身份正确地将 VM 接入到 TSB 服务网格中。

WorkloadEntry 的配置涉及以下信息：
- 服务网格需要注册 VM 工作负载所需的详细信息
- 为 `tctl` 提供了正确信息以启动 VM 接入的注释
- 用于 TSB 可观测性的标签，它们持有工作负载的逻辑服务身份

下面是一个 `WorkloadEntry` 资源的模板示例，突出显示了根据你的环境的具体情况必须配置的属性。

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: ratings-vm
  namespace: bookinfo
  annotations:
    sidecar-bootstrap.istio.io/ssh-host: <ssh-host>
    sidecar-bootstrap.istio.io/ssh-user: istio-proxy
    sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy
    sidecar-bootstrap.istio.io/proxy-image-hub: docker.io/tetrate
    sidecar-bootstrap.istio.io/proxy-instance-ip: <proxy-instance-ip>
spec:
  address: <address>
  labels:
    class: vm
    app: ratings   # 可观测性标签，通过 TSB 可观测性可见
    version: v3    # 可观测性标签，通过 TSB 可观测性可见
  serviceAccount: bookinfo-ratings
  network: <vm-network-name>
```

#### network: &lt;vm-network-name&gt;
在你的 Kubernetes 集群中的服务网格需要知道你的 VM 是否位于可以直接到达 Pod IPs 的网络中。正如防火墙部分所述，这将决定流量是否应该通过 VM 网

关路由。通过添加 `network` 属性并提供 VM 网络的名称，服务网格将启用 VM 网关路由。如果你省略网络属性，则服务网格将假定 VM 在具有直接 IP 连通性的网络上运行。

#### address: &lt;address&gt;
Address 必须保存可以被 Pod 直接连接到的 VM 工作负载的目标 IP。在相同网络场景中，这是一个 pod 可以直接连接到的 VM IP 地址。在网络隔离的情况下，这是 pod 可以到达的 VM IP 地址。例如，如果你对 Kubernetes 和 VM 使用了不同的 VPC，则这可以是一个私有 IP 地址，只要 VPC 路由/对等设置正确即可。在不同云提供商的情况下，这通常是 VM 可以访问的公共 IP 地址。

#### proxy-instance-ip: &lt;proxy-instance-ip&gt;
如果提供了此注释，它必须保存 Istio Proxy sidecar 在 VM 上可以将其侦听器绑定到的 IP 地址。通常，这是从外部接收传入流量的接口的 IP 地址。如果 VM 有一个配置了公共 IP 地址的接口，并且这与 `address` 属性相同，那么可以省略此注释。大多数云提供商的 VM 不会在直接侦听公共 IP 地址的接口上，而是在私有 IP 上。在这种情况下，你必须配置 VM 的内部 IP 地址，以便将外部传入流量路由到该地址。

#### ssh-host: &lt;ssh-host&gt;
当你执行 `tctl` bootstrap 命令时，`tctl` 尝试连接到需要接入的 VM。默认行为是使用在 `address` 属性中找到的 IP 地址。如果运行 `tctl` 的机器与该地址没有直接的 IP 连通性，例如在 `address` 包含私有 IP 地址的情况下，可以设置此可选的 `ssh-host` 注释。在这种情况下，请提供允许 `tctl` 通过 SSH 连接到 VM 的 IP 地址或主机名。

在评分 VM 示例中，我们将假设以下情况：

- 云提供商上的 Kubernetes 集群和本地 VM
- 外部 VM IP 地址未直接绑定到机器上
- VM 上的 Istio Proxy 将侦听 TCP 端口 9080
- `tctl` 和 Kubernetes 都可以通过相同的外部 IP 访问 VM。
- VM 内部 IP: 10.128.0.2
- VM 外部 IP:  35.194.38.142

使用这些假设的示例 `WorkloadEntry` 如下所示：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: ratings-vm
  namespace: bookinfo
  annotations:
    sidecar-bootstrap.istio.io/ssh-host: 35.194.38.142
    sidecar-bootstrap.istio.io/ssh-user: istio-proxy
    sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy
    sidecar-bootstrap.istio.io/proxy-image-hub: docker.io/tetrate
    sidecar-bootstrap.istio.io/proxy-instance-ip: 35.194.38.142
spec:
  address: 10.128.0.2
  labels:
    class: vm
    app: ratings   # 可观测性标签，通过 TSB 可观测性可见
    version: v3    # 可观测性标签，通过 TSB 可观测性可见
  serviceAccount: bookinfo-ratings
  network: <vm-network-name>
```

将其保存为 [`ratings-workloadentry.yaml`](../../assets/setup/ratings-workloadentry.yaml)。你可以将此文件添加到源代码控制中，或者使用 `kubectl` 将其直接应用于你的集群：

```bash
kubectl apply -f ratings-workloadentry.yaml
```

### 创建 Sidecar

现在，我们已经配置了我们的 `WorkloadEntry`，以提供有关启动 VM 接入流程和 IP 连通性的信息，我们需要配置 VM 的 Istio Proxy sidecar。 [Sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/) 资源使你可以控制 Istio Proxy 的配置。在此示例中，Sidecar 配置允许你避免在 VM 上使用 IPtables 重定向流量。

下面的 `Sidecar` 示例显示了评分 VM 示例的配置，侦听 TCP 端口 9080。

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: ratings-vm
  namespace: bookinfo
spec:
  egress: 
    - hosts:
        - "*"
      ports:
        - port: 80
          protocol: HTTP
          bind: 0.0.0.0
  workloadSelector:
    labels:
      app: ratings
```

将其保存为 [`ratings-sidecar.yaml`](../../assets/setup/ratings-sidecar.yaml)。你可以将此文件添加到源代码控制中，或者使用 `kubectl` 将其直接应用于你的集群：

```bash
kubectl apply -f ratings-sidecar.yaml
```

### 接入 VM

使用配置并将其应用于你的 Kubernetes 集群后，VM 工作负载现在已注册到你的服务网格中。随着 VM 和服务网格的准备就绪，我们可以使用 `tctl` 完成实际的接入过程。

`tctl` CLI 将：

- 从服务网格获取引导安全令牌和种子配置
- 将此引导安全令牌和种子配置传输到 VM
- 使用引导安全令牌和种子配置启动 Istio Proxy

由于此接入过程比较复杂，`tctl` 实现了干运行功能。

在实际应用程序中，你可以使用 `--dry-run=false` 选项。

```bash
tctl x sidecar-bootstrap \
    --dry-run=true \
    ratings-vm \
    --access-log-out /var/log/access.log \
    --envoy-image-version v1.16.2
```

你将收到一个包含引导令牌和种子配置的 JSON 输出。此信息必须传输到 VM。

### 在 VM 上启动 Istio 代理

你可以将脚本保存在名为 `sidecar-bootstrap.sh` 的文件中，然后在 VM 上运行。

```bash
# 将引导令牌和种子配置复制到 VM，以及 sidecar-bootstrap.sh 脚本。
# 这里使用 SCP 命令，你可以根据需要使用其他方法。
scp path_to_token_and_config.tar.gz sidecar-bootstrap.sh istio-proxy@<vm-ip>:~
```

在 VM 上运行 `sidecar-bootstrap.sh` 脚本。

```bash
chmod +x sidecar-bootstrap.sh
./sidecar-bootstrap.sh
```

脚本将自动完成以下操作：

- 解压缩引导令牌和种子配置
- 将引导令牌和种子配置复制到 Istio 代理的正确位置
- 使用配置的版本和配置文件启动 Istio 代理

### 验证 VM 接入

一旦 Istio 代理在 VM 上启动，它应该会自动连接到 Istio 控制平面，并成为服务网格的一部分。

要验证接入是否成功，请使用以下步骤：

1. 在 Kubernetes 集群中，确保你的 Bookinfo 示例正常运行。

2. 在 VM 上，使用 `curl` 或其他工具来访问 Bookinfo 示例中的服务，例如 Ratings 服务。

```bash
curl http://<ratings-pod-ip>:9080/ratings
```

在成功连接到服务之后，你应该能够从 VM 访问 Bookinfo 示例中的 Ratings 服务。

## 结论

通过使用 `tctl` 和 Istio 的 `WorkloadEntry` 和 `Sidecar` 资源，你可以将虚拟机（VM）接入到 TSB 服务网格中。这使得你可以将 VM 集成到 Istio 控制平面和数据平面中，从而实现了对 VM 的流量管理和安全性控制。请根据你的特定环境和需求调整本指南中的步骤。

请记得检查 Tetrate 文档以获取最新的信息和更新。

## 相关资源

- [Istio WorkloadEntry 参考](https://istio.io/latest/docs/reference/config/networking/workload-entry/)
- [Istio Sidecar 参考](https://istio.io/latest/docs/reference/config/networking/sidecar/)
- [Tetrate Service Bridge 文档](https://docs.tsb.tetrate.io/)
- [Istio 控制平面指南](https://istio.io/latest/docs/reference/config/installation-options/)
- [Istio 服务网格概述](https://istio.io/latest/docs/concepts/what-is-istio/)
- [Istio 服务网格入门](https://istio.io/latest/docs/setup/getting-started/)
- [Istio 服务网格任务](https://istio.io/latest/docs/tasks/)
- [Tetrate 文档](https://docs.tetrate.io/)
- [Tetrate CLI (`tctl`) 参考](https://docs.tsb.tetrate.io/guides/cli_reference/)

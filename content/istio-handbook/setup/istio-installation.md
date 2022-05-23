---
weight: 10
title: 安装 Istio
date: '2022-05-18T00:00:00+08:00'
type: book
---

{{% callout warning %}}
Istio 官方已不再推荐使用 Operator 来安装 Istio，建议你使用 istioctl 命令或者 Helm 来安装。
{{% /callout %}}

要安装 Istio，我们需要一个运行中的 Kubernetes 集群实例。所有的云供应商都有一个管理的 Kubernetes 集群提供，我们可以用它来安装 Istio 服务网格。

我们也可以在你的电脑上使用以下平台之一在本地运行一个 Kubernetes集群。

要安装 Istio，我们需要一个运行中的 Kubernetes 集群实例。所有的云供应商都有一个管理的 Kubernetes 集群提供，我们可以用它来安装 Istio 服务网格。

我们也可以在你的电脑上使用以下平台之一在本地运行一个 Kubernetes 集群。

- [Minikube](https://istio.io/latest/docs/setup/platform-setup/minikube/)
- [Docker Desktop](https://istio.io/latest/docs/setup/platform-setup/docker/)
- [kind](https://istio.io/latest/docs/setup/platform-setup/kind/)
- [MicroK8s](https://istio.io/latest/docs/setup/platform-setup/microk8s/)

当使用本地 Kubernetes 集群时，确保你的计算机满足 Istio 安装的最低要求（如 16384MB 内存和 4 个 CPU）。另外，确保 Kubernetes 集群的版本是 v1.19.0 或更高。

### Minikube

在这次培训中，我们将使用 Minikube 的 Hypervisor。Hypervisor 的选择将取决于你的操作系统。要安装 Minikube 和 Hypervisor，你可以按照安装说明进行。

安装了 Minikube 后，我们可以创建并启动 Kubernetes 集群。下面的命令使用 VirtualBox 管理程序启动一个 Minikube 集群。

`minikube start --memory=16384 --cpus=4 --driver=virtualbox`

请确保用你所使用的 Hypervisor 的名字替换 `-driver=virtualbox`。关于可用的选项，见下表。

| 标志名称     | 更多信息                                                     |
| ------------ | ------------------------------------------------------------ |
| `hyperkit`   | [HyperKit](https://github.com/moby/hyperkit)                 |
| `hyperv`     | [Hyper-V](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/) |
| `kvm2`       | [KVM](https://www.linux-kvm.org/page/Main_Page)              |
| `docker`     | [Docker](https://hub.docker.com/search?q=&type=edition&offering=community&sort=updated_at&order=desc) |
| `podman`     | [Podman](https://podman.io/getting-started/installation.html) |
| `parallels`  | [Parallels](https://www.parallels.com/)                      |
| `virtualbox` | [VirtualBox](https://www.virtualbox.org/)                    |
| `vmware`     | [VMware Fusion](https://www.vmware.com/products/fusion.html) |

为了检查集群是否正在运行，我们可以使用 Kubernetes CLI，运行 kubectl get nodes 命令。

```bash
$ kubectl get nodes
NAME       STATUS   ROLES    AGE    VERSION
minikube   Ready    master   151m   v1.19.0
```

> 注意：如果你使用 [Brew 软件包管理器](https://brew.sh)安装了 Minikube，你也安装了 Kubernetes CLI。

### Kubernetes CLI

如果你需要安装 Kubernetes CLI，请遵循[这些说明](https://kubernetes.io/docs/tasks/tools/install-kubectl/)。

我们可以运行 `kubectl version` 来检查 CLI 是否已经安装。你应该看到与此类似的输出。

```bash
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.2", GitCommit:"f5743093fd1c663cb0cbc89748f730662345d44d", GitTreeState:"clean", BuildDate:"2020-09-16T21:51:49Z", GoVersion:"go1.15.2", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.0", GitCommit:"e19964183377d0ec2052d1f1fa930c4d7575bd50", GitTreeState:"clean", BuildDate:"2020-08-26T14:23:04Z", GoVersion:"go1.15", Compiler:"gc", Platform:"linux/amd64"}
```

### 下载 Istio

在本课程中，我们将使用 Istio 1.10.3。安装 Istio 的第一步是下载 Istio CLI（istioctl）、安装清单、示例和工具。

安装最新版本的最简单方法是使用 `downloadIstio` 脚本。打开一个终端窗口，打开你要下载 Istio 的文件夹，然后运行下载脚本。

```sh
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.10.3 sh -
```

Istio 发行版被下载并解压到名为 `istio-1.9.0` 的文件夹中。为了访问 istioctl，我们应该把它添加到 path 中。

```sh
$ cd istio-1.10.3
$ export PATH=$PWD/bin:$PATH
```

要检查 istioctl 是否在 path 里，运行 `istioctl version`。你应该看到这样的输出。

```sh
$ istioctl version
no running Istio pods in "istio-system"
1.10.3
```

### 安装 Istio

Istio 支持多个配置文件（profile）。配置文件之间的区别在于所安装的组件。

```sh
$ istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    minimal
    preview
    remote
```

推荐用于生产部署的配置文件是 default 配置文件。我们将安装 demo 配置文件，因为它包含所有的核心组件，启用了跟踪和日志记录，并且是为了学习不同的 Istio 功能。

我们也可以从 minimal 的组件开始，以后单独安装其他功能，如 ingress 和 egress 网关。

因为我们将使用 Istio 操作员进行安装，所以我们必须先部署 Operator。

要部署 Istio Operator，请运行：

```sh
$ istioctl operator init
Using operator Deployment image: docker.io/istio/operator:1.9.0
✔ Istio operator installed
✔ Installation complete
```

init 命令创建了 istio-operator 命名空间，并部署了 CRD、Operator Deployment 以及 operator 工作所需的其他资源。安装完成后，Operator 就可以使用了。

要安装 Istio，我们必须创建 IstioOperator 资源，并指定我们要使用的配置配置文件。

创建一个名为 demo-profile.yaml 的文件，内容如下：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: demo-istio-install
spec:
  profile: demo
```

我们还在文件中添加了命名空间资源，以创建 `istio-system` 命名空间。

我们需要做的最后一件事是创建资源：

```sh
$ kubectl apply -f demo-profile.yaml  
namespace/istio-system created
istiooperator.install.istio.io/demo-istio-install created
```

一旦 Operator 检测到 IstioOperator 资源，它将开始安装 Istio。整个过程可能需要5分钟左右。

为了检查安装的状态，我们可以看看 `istio-system` 命名空间中的Pod的状态。

```sh
$ kubectl get po -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-6db9994577-sn95p    1/1     Running   0          79s
istio-ingressgateway-58649bfdf4-cs4fk   1/1     Running   0          79s
istiod-dd4b7db5-nxrjv                   1/1     Running   0          111s
```

当所有的 Pod 都在运行时，Operator 已经完成了 Istio 的安装。

### 启用 sidecar 注入

正如我们在上一节中所了解的，服务网格需要与每个应用程序一起运行的 sidecar 代理。

要将 sidecar 代理注入到现有的 Kubernetes 部署中，我们可以使用 istioctl 命令中的 `kube-inject` 动作。

然而，我们也可以在任何 Kubernetes 命名空间上启用自动 sidecar 注入。如果我们用 `istio-injection=enabled` 标记命名空间，Istio 会自动为我们在该命名空间中创建的任何 Kubernetes Pod 注入 sidecar。

让我们通过添加标签来启用默认命名空间的自动 sidecar 注入。

```sh
$ kubectl label namespace default istio-injection=enabled
namespace/default labeled
```

要检查命名空间是否被标记，请运行下面的命令。`default` 命名空间应该是唯一一个启用了该值的命名空间。

```sh
$ kubectl get namespace -L istio-injection
NAME              STATUS   AGE   ISTIO-INJECTION
default           Active   32m   enabled
istio-operator    Active   27m   disabled
istio-system      Active   15m
kube-node-lease   Active   32m
kube-public       Active   32m
kube-system       Active   32m
```

现在我们可以尝试在 `default` 命名空间创建一个 Deployment，并观察注入的代理。我们将创建一个名为 `my-nginx` 的 Deployment，使用 nginx 镜像的单一容器。

```sh
$ kubectl create deploy my-nginx --image=nginx
deployment.apps/my-nginx created
```

如果我们看一下 Pod，你会发现 Pod 里有两个容器。

```sh
$ kubectl get po
NAME                        READY   STATUS    RESTARTS   AGE
my-nginx-6b74b79f57-hmvj8   2/2     Running   0          62s
```

同样地，描述 Pod 显示 Kubernetes 同时创建了一个 `nginx` 容器和一个 `istio-proxy` 容器：

```sh
$ kubectl describe po my-nginx-6b74b79f57-hmvj8
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  118s  default-scheduler  Successfully assigned default/my-nginx-6b74b79f57-hmvj8 to minikube
  Normal  Pulling    117s  kubelet            Pulling image "docker.io/istio/proxyv2:1.9.0"
  Normal  Pulled     116s  kubelet            Successfully pulled image "docker.io/istio/proxyv2:1.9.0" in 1.102544635s
  Normal  Created    115s  kubelet            Created container istio-init
  Normal  Started    115s  kubelet            Started container istio-init
  Normal  Pulling    115s  kubelet            Pulling image "nginx"
  Normal  Created    78s   kubelet            Created container nginx
  Normal  Pulled     78s   kubelet            Successfully pulled image "nginx" in 36.157915646s
  Normal  Started    77s   kubelet            Started container nginx
  Normal  Pulling    77s   kubelet            Pulling image "docker.io/istio/proxyv2:1.9.0"
  Normal  Pulled     76s   kubelet            Successfully pulled image "docker.io/istio/proxyv2:1.9.0" in 1.050876635s
  Normal  Created    76s   kubelet            Created container istio-proxy
  Normal  Started    76s   kubelet            Started container istio-proxy
```

运行下面的命令，删除部署：

```sh
$ kubectl delete deployment my-nginx
deployment.apps "my-nginx" deleted
```

### 更新和卸载 Istio

如果我们想更新当前的安装或改变配置文件，我们将需要更新先前部署的 `IstioOperator` 资源。

要删除安装，我们必须删除 `IstioOperator`，比如说：

```sh
$ kubectl delete istiooperator -n istio-system demo-istio-install
```

一旦 Operator 删除了Istio，我们也可以通过运行下面的命令来删除 Operator：

```sh
$ istioctl operator remove
```

请确保在删除 Operator 之前先删除 `IstioOperator` 资源。否则，可能会有剩余的 Istio 资源。

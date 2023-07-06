---
title: "使用 OCI 容器运行 WebAssembly 工作负载"
date: 2023-04-03T20:00:00+08:00
draft: false
authors: ["Aditya R"]
summary: "本文介绍了如何使用 OCI 容器来运行 WebAssembly 工作负载。WebAssembly（也称为 Wasm）是一种可移植的二进制指令格式，具有可嵌入和隔离的执行环境，适用于客户端和服务器应用。WebAssembly 可以看作是一种小巧、快速、高效、安全的基于栈的虚拟机，设计用于执行不关心 CPU 或操作系统的可移植字节码。WebAssembly 最初是为 web 浏览器设计的，用来作为函数的轻量级、快速、安全、多语言的容器，但它不再局限于 web。在 web 上，WebAssembly 使用浏览器提供的现有 API。WebAssembly System Interface（WASI）是为了填补 WebAssembly 和浏览器外系统之间的空白而创建的。这使得非浏览器系统可以利用 WebAssembly 的可移植性，使 WASI 成为分发和隔离工作负载时的一个很好的选择。文章中介绍了如何配置容器运行时来从轻量级容器镜像中运行 Wasm 工作负载，并给出了一些使用示例。"
tags: ["WebAssembly", "OCI","容器","crun"]
categories: ["WebAssembly"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://opensource.com/article/22/10/wasm-containers
---

> 译者注：本文介绍了如何使用 OCI 容器来运行 WebAssembly 工作负载。WebAssembly（也称为 Wasm）是一种可移植的二进制指令格式，具有可嵌入和隔离的执行环境，适用于客户端和服务器应用。WebAssembly 可以看作是一种小巧、快速、高效、安全的基于栈的虚拟机，设计用于执行不关心 CPU 或操作系统的可移植字节码。WebAssembly 最初是为 web 浏览器设计的，用来作为函数的轻量级、快速、安全、多语言的容器，但它不再局限于 web。在 web 上，WebAssembly 使用浏览器提供的现有 API。WebAssembly System Interface（WASI）是为了填补 WebAssembly 和浏览器外系统之间的空白而创建的。这使得非浏览器系统可以利用 WebAssembly 的可移植性，使 WASI 成为分发和隔离工作负载时的一个很好的选择。文章中介绍了如何配置容器运行时来从轻量级容器镜像中运行 Wasm 工作负载，并给出了一些使用示例。
>

WebAssembly（也称为 Wasm）以其可嵌入和隔离的执行环境而成为一种流行的便携式二进制指令格式，用于客户端和服务器应用程序。将 WebAssembly 视为一种小型、快速、高效且非常安全的基于堆栈的虚拟机，专门用于执行可移植的字节码，不在乎它运行在哪个 CPU 或操作系统上。WebAssembly 最初是为 Web 浏览器设计的，用于成为函数的轻量级、快速、安全和多语言容器，但它不再仅限于 Web。

在 Web 上，WebAssembly 使用浏览器提供的现有 API。WebAssembly 系统接口（WASI）的创建填补了 WebAssembly 和运行在浏览器外部的系统之间的空白。这使非浏览器系统能够利用 WebAssembly 的可移植性，使 WASI 成为在分发时具有可移植性和在运行负载时具有隔离性的良好选择。

WebAssembly 提供了几个优点。因为它是平台中立的，所以可以在多个操作系统和架构上同时编译和执行一个单一的二进制文件，具有非常低的磁盘占用和启动时间。有用的安全功能包括模块签名和可以在运行时级别上控制的安全调节器，而不是依赖于主机操作系统的用户权限。封闭式内存仍然可以由现有的容器工具基础架构进行管理。

在本文中，我将通过一个配置容器运行时来运行轻量级容器镜像中的 Wasm 工作负载的方案来讲解。

## WebAssembly 在云基础设施上的采用和阻碍

WebAssembly 和 WASI 相当新，因此尚未设置在容器生态系统中本地运行 Wasm 工作负载的标准。本文仅介绍一种解决方案，但还有其他可行的方法。

其中一些解决方案包括使用兼容 Wasm 的组件替换本机 Linux 容器运行时。例如，Krustlet v1.0.0-alpha1 允许用户引入 Kubernetes 节点，其中 Krustlet 用作标准 kubelet 的替代品。这种方法的局限性在于用户必须在 Linux 容器运行时和 Wasm 运行时之间进行选择。

另一种解决方案是使用带有 Wasm 运行时的基本镜像，并手动调用编译后的二进制文件。但是，如果我们在低于容器运行时的一级别调用 Wasm 运行时，这种方法会使容器镜像膨胀，这不一定是必需的。

我将描述如何通过创建一个混合设置来避免这种情况，其中现有的 Open Containers Initiative（OCI）运行时可以运行本地 Linux 容器和与 WASI 兼容的工作负载。

## 在混合设置中使用 crun 运行 Wasm 和 Linux 容器

一些上述问题可以通过允许现有的 OCI 运行时在较低级别上调用 Linux 容器和 Wasm 容器来轻松解决。这避免了依赖容器镜像携带 Wasm 运行时或引入仅支持 Wasm 容器的基础架构新层的问题。

可以处理此任务的一个容器运行时是 crun。

Crun 快速，占用内存低，是一个完全符合 OCI 的容器运行时，可以用作现有容器运行时的替代品。Crun 最初是编写用于运行 Linux 容器的，但它还提供了能够在本地方式下在容器沙盒中运行任意扩展的处理程序。

这是用 crun 替换现有运行时的一种非正式方式，仅用于展示 crun 是您现有 OCI 运行时的完整替代品。

```bash
$ mv /path/to/exisiting-runtime /path/to/existing-runtime.backup
$ cp /path/to/crun /path/to/existing-runtime
```

其中之一处理程序是 `crun-wasm-handler`，它将特别配置的容器镜像（*Wasm 兼容镜像*）委派给现有 Wasm 运行时的部分，以本地方式在 crun 沙盒内运行。这样，终端用户无需自己维护 Wasm 运行时。

Crun 与 [wasmedge](<https://wasmedge.org/>)、[wasmtime](<https://wasmtime.dev/>) 和 [wasmer](<https://wasmer.io/>) 具有本地集成，以支持此功能。它在 crun 检测到配置的镜像是否包含任何 Wasm/WASI 工作负载时动态地调用这些运行时的部分，同时仍支持本地 Linux 容器。

有关使用 Wasm/WASI 支持构建 crun 的详细信息，请参见 [GitHub 上的 crun 存储库](https://github.com/containers/crun/)。

## 在 Podman 和 Kubernetes 上使用 Buildah 构建和运行 Wasm 镜像

用户可以在 Podman 和 Kubernetes 上使用 crun 作为 OCI 运行时来创建和运行平台无关的 Wasm 镜像。以下是教程：

### 使用 Buildah 创建 Wasm 兼容镜像

Wasm/WASI 兼容镜像很特别。它们包含一个魔术注释，可帮助像 crun 这样的 OCI 运行时分类别它是 Linux 本机镜像还是带有 Wasm/WASI 工作负载的镜像。然后，如果需要，它可以调用处理程序。

使用任何容器镜像构建工具都可以非常轻松地创建这些 Wasm 兼容镜像，但是对于本文，我将演示如何使用 [Buildah](https://opensource.com/article/22/2/build-your-own-container-linux-buildah)。

1. 编译您的 `.wasm` 模块。
2. 使用您的 `.wasm` 模块准备一个 Containerfile。

```dockerfile
FROM scratch

COPY hello.wasm /

CMD ["/hello.wasm"]
```

3. 使用 Buildah 使用注释 `module.wasm.image/variant=compat` 构建 Wasm 镜像。

```bash
$ buildah build --annotation "module.wasm.image/variant=compat" -t mywasm-image
```

构建完镜像并且容器引擎已配置为使用 crun，crun 将自动完成工作并通过配置的 Wasm 处理程序运行提供的工作负载。

### 在 Podman 中运行 WASM 工作负载

Crun 是 Podman 的默认 OCI 运行时。Podman 包含旋钮和处理程序，可利用大多数 crun 功能，包括 crun Wasm 处理程序。构建 Wasm 兼容镜像后，它可以像任何其他容器镜像一样由 Podman 使用：

```bash
$ podman run mywasm-image:latest
```

Podman 使用 crun 的 Wasm 处理程序运行请求的 Wasm 兼容镜像 `mywasm-image:latest`，并返回确认我们的工作负载已执行的输出。

```bash
$ hello world from the webassembly module !!!!
```

### Kubernetes 支持和测试的容器运行时接口（CRI）实现

以下是配置两个流行的容器运行时的方法：

### CRI-O

- 通过编辑 `/etc/crio/crio.conf` 上的配置将 CRI-O 配置为使用 crun 而不是 runc。Red Hat OpenShift 文档包含有关 [配置 CRI-O](https://docs.openshift.com/container-platform/3.11/crio/crio_runtime.html#configure-crio-use-crio-engine) 的更多详细信息。
- 使用 `sudo systemctl restart crio` 重新启动 CRI-O。
- CRI-O 自动将 pod 注释传播到容器规范。

### Containerd

- Containerd 支持通过自定义配置定义在 `/etc/containerd/config.toml` 中切换容器运行时。
- 通过确保运行时二进制文件指向 crun，将 containerd 配置为使用 crun。有关详细信息，请参见 [containerd 文档](https://github.com/containerd/containerd/blob/main/docs/cri/config.md)。
- 通过设置 `pod_annotations = ["module.wasm.image/variant.*"]` 在配置中允许列出 Wasm 注释，以便将它们传播到 OCI 规范。然后使用 `sudo systemctl start containerd` 重新启动 containerd。
- 现在，containerd 应该将 Wasm pod 注释传播到容器。

以下是与 CRI-O 和 containerd 兼容的 Kubernetes pod 规范示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-wasm-workload
  namespace: mynamespace
  annotations:
    module.wasm.image/variant: compat
spec:
  containers:
  - name: wasm-container
    image: myrepo/mywasmimage:latest
```

## 已知问题和解决方法

复杂的 Kubernetes 基础架构包含 pod，而且在许多情况下，这些 pod 还包括 sidecar。这意味着当部署包含 sidecar 并且 sidecar 容器不包含 Wasm 入口点（例如像 Linkerd、Gloo 和 Istio 这样的服务网格或 Envoy 这样的代理的基础架构设置）时，crun 的 Wasm 集成将无用。

您可以通过添加两个智能注释来解决此问题，用于 Wasm 处理程序：`compat-smart` 和 `wasm-smart`。这些注释充当智能开关，仅在容器需要时切换 Wasm 运行时。因此，在运行带有 sidecar 的部署时，只有包含有效 Wasm 工作负载的容器才由 Wasm 处理程序执行。常规容器像往常一样被委派给本机 Linux 容器运行时。

因此，在为这种用例构建镜像时，请使用注释 `module.wasm.image/variant=compat-smart`，而不是 `module.wasm.image/variant=compat`。

您可以在 [GitHub 上的 crun 文档](https://github.com/containers/crun/blob/main/docs/wasm-wasi-on-kubernetes.md#known-issues) 中找到其他已知问题。

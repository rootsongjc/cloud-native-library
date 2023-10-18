---
title: 基本故障排除
weight: 1
---

本文档介绍了在 TSB 中进行基本故障排除的一些可能方法，以便查找特定路由的错误配置问题或 `50x` 错误的常见原因。

## 系统架构

在本文档中，采用了以下具有 Tier1-Tier2 设置的系统架构：

有两个不同的集群，`training-mp` 包含管理平面和配置为 tier1 的控制平面，`training-cp` 配置为 tier2，包含 `bookinfo` 和 `httpbin` 应用程序。

![](../../assets/operations/troubleshooting-diagram.png)

## Tier1 网关故障排除

当检测到 `50x` 错误时，重要的是要理解错误消息，因为它会指向不同的信息源。

例如，假设你使用 `curl` 发出了一个 HTTP 请求到由 TSB 控制的服务之一，并且观察到类似以下的错误：

```bash
Failed to connect to <hostname> port <port>: Connection refused
```

这通常意味着没有配置监听器。这又意味着我们要么：

1. 缺少网关对象
2. 访问了错误的端口
3. 网关没有正确配置，或者
4. Tier1 网关的 Pod 没有运行。

要检查监听器是否存在，你可以使用 `istioctl`：

```bash
$ istioctl pc listener <ingressgateway>.<namespace>
```

如果没有监听器，或者你想检查当前配置，你需要审查你的网关配置。要获取网关对象，使用 `kubectl`：

```bash
kubectl get gateway
```

如果网关不存在，你需要排查为什么 XCP 没有创建配置。在这种情况下，请定位管理平面命名空间中的 `mpc` Pod，并查找可能指向错误配置的 Webhook 错误。

如果网关和虚拟服务已创建，但仍然在 HTTP 请求中获得 `50x` 错误，例如以下错误：

```bash
HTTP/2 503
```

在这种情况下，请查看 `ingressgateway` 的日志。由于在这种情况下系统配置为 tier1-tier2 设置，因此首先应该检查 `tier1gateway`。

查找相应 Pod 的日志。根据问题的性质，你可能需要启用跟踪日志以进行进一步的调查。

如果你找到以下类似的条目，这意味着无法找到到达 tier2 网关的路由。

```bash
HTTP/2" 503 NR
```

如果是这种情况，请尝试检查以下内容：

### 确保已应用 `nodeSelector` 注释

如果在 XCP-edge 服务中使用 NodePort，请记住你必须在 tier1 和 tier2 中都添加以下注释：

```bash
traffic.istio.io/nodeSelector: {"value":"value"}'
```

### 检查 `tier1gateway` 配置

可以通过将流量路由到特定的集群名称或使用标签来配置 `tier1gateway`。确保集群或标签名称在 [`tier1gateway`](https://docs.tetrate.io/service-bridge/latest/en-us/refs/tsb/gateway/v2/tier1_gateway) 配置的 `spec.externalServers.name[x].clusters` 字段中是正确的。

你可以使用以下命令获取 `tier1gateway` 对象：

```bash
$ tctl get t1 -w <workspace> -l <gatewaygroup> <name> -o yaml
 
  …
  externalServers:
  - clusters:
    - name: training-cp
    hostname: bookinfo
    …
  - clusters:
    - labels:
        tier: tier2
    hostname: httpbin
    …
```

并将其与 [cluster](https://docs.tetrate.io/service-bridge/latest/en-us/refs/tsb/v2/cluster) 对象进行比较：

```bash
$ tctl get cluster <name> -o yaml

…
metadata:
  labels:
    tier: tier2
  name: training-cp
…
```

### 检查网络之间的通信权限

如果在集群对象中定义了一个 `network`，并且参与的集群并不都共享相同的 `network`，请检查是否存在一个允许在不同网络之间进行通信的 [组织设置](https://docs.tetrate.io/service-bridge/latest/en-us/refs/tsb/v2/organization_setting)。

```bash
$ tctl get os
```

修复此问题后，你应该会在命名空间 `xcp-multicluster` 中看到创建的服务。该服务条目是为多集群目的而创建的，还会在应用程序命名空间中创建目标规则以设置 mTLS。

如果此时你仍然注意到从 `tier1gateway` 获取到 503 错误，请检查 [错误代码](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage) 以更好地了解可能导致错误的原因。

---

在此时使用 `istioctl` 命令也非常有用，因为很可能在 tier1 - tier2 情况下，你会遇到下游的某些问题。

首先，请检查你的 `tier1gateway` 的配置是否已同步，检查状态中是否存在 `SYNC`：

```bash
$ istioctl ps
```

验证你要访问的路由是否存在：

```bash
$ istioctl pc route <ingressgateway>.<namespace>
```

如果路由不存在，那么 `tier1gateway` 对象中可能存在配置错误。如果存在，请检查服务的 `cluster`：

```bash
$ istioctl pc cluster <ingressgateway>.<namespace>
```

你应该能够在上述命令的输出中看到子集和目标规则。检查目标规则的配置是否正确。

最后，请检查 `endpoints`。检查配置以查看下游是否正常：

```bash
$ istioctl pc endpoint <ingressgateway>.<namespace>
```

如果所有上述都正确，那么很可能你需要查看 `tier2gateway`。

在 `tier1gateway` 的日志中检查是否存在类似以下的错误：

```bash
HTTP/2" 503 LR,URX
```

这很可能意味着从 `tier1gateway` 到 `tier2gateway` 的连接超时。尝试使用 `netcat` 查看是否可以访问 `tier2gateway`。如果无法成功连接到 `tier2gateway`，可能存在配置错误，或者中间可能有阻止通信的防火墙。

你可能还可以在 `ingressgateway` 的日志中找到一些有用的信息。如果你在日志中找到类似以下的错误消息，这意味着 `istio-system` 命名空间中的 [`cacert`](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/) 密钥并未由两个集群中的相同根（或中间）CA 签名。

```bash
$ HTTP/2" 503 UF,URX "-" "TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED"
```

如果你对证书进行了更改，你将需要重新启动所有 sidecar 和网关，或者等待 30 分钟，直到组件从 `istiod` 获取新证书。这些更新之间的间隔可以配置，但默认值为 30 分钟。

## Tier2Gateway 故障排除

如果调试 `tier1gateway` 不足以解决问题，你将不得不执行与你在 `tier2gateway` 上执行的大部分类似的操作，并了解你的问题是否源自配置错误或配置传播问题（即 `XCP`）。

检查是否已在 `tier2` 命名空间中创建了网关，可以使用 `kubectl get gateway` 进行检查。如果网关不存在，请在 XCP 方面检查。你可以从管理平面命名空间中的 `mpc` Pod 中查看是否存在任何 Webhook 问题。

如果网关已创建，请验证监听器是否正确创建。

```bash
$ istioctl pc listener <ingressgateway>.<namespace>
```

在 [`ingressgateway`](https://docs.tetrate.io/service-bridge/latest/en-us/refs/install/dataplane/v1alpha1/spec) 资源中还必须包含端口 15443 的监听器，因为从 `tier1` 到 `tier2` 的流量将需要使用此端口。还重要的是检查端口 15443 是否在监听器列表的第一个条目中指定，因为一些云供应商会将第一个端口用于负载均衡器的健康检查。

如果在检查了监听器是否正确创建后，问题仍然存在，你需要检查 `tier2gateway` 的日志。如果在这些日志中看到了 `50x` 错误，则很可能是应用程序本身存在问题，或者从 `istiod` 到 `tier2gateway` 的配置传播存在问题。

如果需要进一步的故障排除，那么你将需要启用跟踪日志以找出根本原因：

```bash
kubectl exec <pod> -c istio-proxy -- pilot-agent request POST ‘logging?level=trace'
```

你还可以检查是否从 `istiod` 接收到配置：

```bash
$ istioctl ps
```

如果配置未正确同步，请检查 `istiod` 与 `tier2gateway

` 之间是否有可能阻止通信的任何网络条件。

还要验证 `istiod` 命名空间中的 `istiod` Pod 是否正常运行。你可能存在资源问题，可能会阻止配置的发送。

如果要验证特定主机名的 `tier2gateway` 中的所有配置，可以获取配置转储：

```bash
kubectl exec <pod> -c istio-proxy -- pilot-agent request GET config_dump > config_dump.json
```

## XCP 故障排除

如果注意到 `XCP` 没有创建你期望的配置，请检查管理平面命名空间中 `mpc` Pod 的日志。

在这些日志中，你可能会发现验证错误，指示了从 TSB 转换到 XCP API 的配置存在问题。例如，你可能会看到类似以下的条目：

```bash
kubectl logs -n tsb <mpc>

2022-03-02T13:58:26.153872Z     error   mpc/config      failed to convert TSB config into its XCP equivalent: no gateway object found for reference "httpbin/httpbin-gw" in "organizations/<org>/tenants/<tenant>/workspaces/<ws>/gatewaygroups/<gg>/virtualservices/<vs>"
```

如果在 `mpc` 中没有 Webhook 错误，然后检查集群应用程序命名空间中 `edge` Pod 的日志。 

如果一切正常，你应该能够在 `istio-system` 命名空间中看到应用于所有配置的日志：

```bash
kubectl logs -n istio-system <edge>

2022-03-09T11:17:25.492365Z     debug   configapply     ===BEGIN: Apply request for <n> objects in istio-system namespace
```

如果你要查找的对象在此列表中不存在，那么可能是 `XCP edge` 或 `XCP central` 中的问题。

要启用 `XCP edge` 的调试日志，你可以对部署进行如下修改（这将重新启动 Pod）：

```bash
kubectl edit deployment edge -n istio-system
```

具体取决于你要排查的问题，你可能必须更详细地配置记录器。例如，如果你想为每个记录器配置不同的记录级别，你可以使用以下命令：

```bash
- --log_output_level
default:info,transform:info,discovery-server:info,configapply:debug,translator:debug,model:debug,istiod-discovery:error,cluster-gen:error,stream:debug
```

或者，你可以一次性为所有记录器设置日志级别：

```bash
- --log_output_level
- default:debug
```

如果要永久更改所有未来 `XCP edge` 组件的日志记录配置，你可以为控制平面运算符创建一个覆盖：

```bash
          overlays:
          - apiVersion: install.xcp.tetrate.io/v1alpha1
            kind: EdgeXcp
            name: edge-xcp
            patches:
            - path: spec.logLevels
              value: default:info,transform:info,discovery-server:info,configapply:debug,translator:debug,model:debug,istiod-discovery:error,cluster-gen:error,stream:debug
```

有了调试模式下的 XCP edge，你应该能够看到错误并确定根本原因是否在集群中。如果不在集群中，你将不得不在管理平面命名空间中执行相同的操作以解决 `XCP cetnral` 的问题。

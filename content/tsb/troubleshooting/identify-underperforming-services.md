---
title: 识别性能不佳的服务
description: 导出流量指标和跟踪信息，并分析性能不佳的服务。
weight: 8
---

服务性能降级可能非常难以理解和隔离：
- 数据太多，难以查找性能问题的原因
- 应用程序行为的专家（开发团队）通常无法访问运行中的集群

Tetrate Service Bridge 提供了一组工具，可以：
- 允许 TSB 操作员从运行中的集群中检索服务性能数据的存档
- 允许应用程序开发人员查询此数据以识别最慢的事务（或带有错误的事务）并确定与慢响应相关的调用图。

在开始之前，请确保你已经：
- 熟悉[TSB 概念](../../concepts/)
- 安装[TSB 演示](../../setup/self-managed/demo-installation)环境
- 部署[Istio Bookinfo](../../quickstart/deploy-sample-app)示例应用程序

## 收集数据

TSB 操作员可以使用 `tctl` 收集集群状态。该状态包括来自工作负载的代理日志、Istio 控制平面信息、节点信息、`istioctl analyze` 和其他运行时信息。数据导出为一个 tar 文件。

```sh
Usage:
  tctl collect [flags]

Examples:

# 收集数据，不进行任何模糊处理或删除
tctl collect

# 收集数据但不存档结果（用于本地调试）
tctl collect --disable-archive

# 收集数据并使用用户提供的正则表达式进行模糊处理
tctl collect --redact-regexes <regex-one>,<regex-two>

# 收集数据并使用预设进行模糊处理
tctl collect --redact-presets networking
```

运行 `tctl collect` 需要管理员权限。生成的 tar 文件可以与应用程序团队共享，以供分析和解释，使用 `tctl troubleshoot`。

## 分析数据

然后，任何用户都可以运行 `tctl troubleshoot` 来检查收集的 tar 文件，并生成有关文件中记录的事务的各种报告：
- 转储集群信息以识别工作负载
- 分析对命名工作负载的请求，以识别最慢的响应和错误响应
- 区分 sidecar 性能和应用程序性能
- 获取请求 ID，然后为这些请求生成完整的跟踪（调用图）

### 分析集群数据

```sh
Usage:
  tctl experimental troubleshoot log-explorer cluster [flags]

Examples:
  tctl experimental troubleshoot log-explorer cluster [tar file]

Flags:
  -h, --help               帮助
  -n, --namespace string   仅列出指定命名空间的详细信息
      --workspace string   仅列出指定的工作空间的详细信息
```

`troubleshoot log-explorer cluster` 提供了有关在集群中运行的所有工作负载的详细信息。用户可以通过应用筛选器（如 `--workspace` 或 `--namespace`）获取整个集群状态的子集。

```sh
$: tctl experimental troubleshoot log-explorer cluster tctl-debug-1664467971183386000.tar.gz --workspace organizations/tetrate/tenants/payment/workspaces/payment-ws
namespaces:
    payment-channel:
        services:
            details:
                pods:
                - details-v1-7d88846999-wgmSV 
            productpage:
                pods:
                - productpage-v1-7795568889-tghhb 
            ratings:
                pods:
                - ratings-v1-754f9c4975-x9h86
            tsb-gateway-bookinfo:
                pods:
                - tsb-gateway-bookinfo-6c46758bf6-5q6vw 
    payment-offers:
        services:
            reviews:
                pods:
                - reviews-primary-54c7dd49dc-8658t 
            reviews-canary:
                pods: []
            reviews-primary:
                pods:
                - reviews-primary-54c7dd49dc-8658t
nodes:
- gke-cp-cluster-1-default-pool-1119254c-w7i
- gke-cp-cluster-1-default-pool-a03a3024-7519
- gke-cp-cluster-1-default-pool-a03a3024-btfs
- gke-cp-cluster-1-default-pool-e090b6ac-trp
workspaces:
- organizations/tetrate/tenants/payment/workspaces/payment-ws
```

### 分析服务数据

```sh
Usage:
  tctl experimental troubleshoot log-explorer service [flags]

Examples:
  tctl experimental log-explorer service [tar file] [service]

Flags:
      --all                显示所有请求，而不仅仅是最长的请求和带有错误的请求。
      --full-log           打印完整的 Envoy 访问日志，而不是摘要。
  -h, --help               帮助
      --limit int          要显示的请求数量（默认为 10）
  -n, --namespace string   包含服务的命名空间。
```

`troubleshoot log-explorer service` 提供了有关 10 个最长请求的详细信息。它输出了 Envoy sidecar 内部和应用程序服务内部消耗的时间的摘要。

![tctl troubleshoot log-explorer service](../../assets/tctl-service.png)

通过此报告，用户可以获取消耗时间最长的请求的请求 ID，以便在下一步进行分析。也可以使用 `--full-log` 标志访问 Envoy 请求日志信息。

### 分析请求数据

```sh
 Usage:
  tctl experimental troubleshoot log-explorer request [flags]

Examples:
  tctl experimental log-explorer request [tar file] [requestID]

Flags:
  -h, --help                 帮助
  -o, --output-type string   选择输出类型，可用格式为 json 和 yaml，默认格式为 yaml（默认为 "yaml"）
```

`tr

oubleshoot log-explorer request` 报告了由提供的 `requestID` 标识的单个请求的跟踪。它输出了从 IngressGateway Pod IP 到最终应用工作负载的请求链，报告了 Envoy sidecar 和应用服务消耗的总时间，以及诸如 `requestType`（指示请求是 `inbound` 还是 `outbound`）、工作负载的命名空间和名称以及 `calledBy` IP 和端口等详细信息。

![tctl 问题排查 log-explorer 请求](../../assets/tctl-request.png)

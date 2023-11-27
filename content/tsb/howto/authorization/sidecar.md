---
title: 使用外部授权进行服务到服务的授权
weight: 1
description: 演示如何使用 OPA 授权服务到服务的流量。
---

[Tetrate Service Bridge (TSB)](../../../concepts/terminology##tetrate-service-bridge-tsb) 提供了授权功能，用于授权来自另一个服务的每个 HTTP 请求（"服务到服务"请求）。

TSB 支持*本地*授权，使用 JWT 声明，以及*外部*授权，后者使用在外部运行的服务来确定是否应允许或拒绝请求。外部授权可以用于网关和工作负载（通过它们的 Sidecar）。

如果你有一个独立的内部系统，或者希望与第三方授权解决方案（如 [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) 或 [PlainID](https://www.plainid.com/)）集成，你可以决定使用外部授权系统。

本文描述了如何使用 OPA 作为示例配置服务到服务的授权。OPA 是一个开源的通用策略引擎，提供高级声明性语言，让你可以将策略规定为代码。

{{<callout note "OPA 支持">}}
Tetrate 不提供对 OPA 的支持。如果你需要针对你的用例支持，请查找其他支持。
{{</callout>}}

在开始之前，请确保你已经完成以下步骤：

- 熟悉 [TSB 概念](../../../concepts/)
- 安装 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation) 进行快速安装
- 完成了 TSB 使用快速入门。本文假设你已经创建了一个租户，并熟悉 [工作空间](../../../concepts/terminology#workspace) 和配置组。还需要将 `tctl` 配置到你的 TSB 环境。

## 概述

以下图表显示了在使用外部授权系统授权服务到服务请求时的请求和响应流程。

![](../../../assets/howto/service-to-service-authorization.png)

期望的结果是能够从"Sleep 工作负载"向"`httpbin` with OPA 工作负载"发送请求，并通过 OPA 执行适当的授权检查。如果从"Sleep 工作负载"发出的请求被视为未经授权，则应返回`403` Forbidden。

请注意，尽管在此示例中，你将 OPA 部署为 Pod 内的 Sidecar，但也可以将 OPA 部署为单独的 Pod。如果将 OPA 部署为单独的 Pod，你将需要自行调查在稍后指定外部系统的 URL 时使用的值。

## 设置服务

### 设置 `httpbin` 服务

首先设置"服务器端"，即图表中的"`httpbin` with OPA 工作负载"组件。

#### OPA 策略

在启动服务之前，你需要创建包含 OPA 策略的 Kubernetes Secret。

以下是你将用于授权请求的 OPA 策略示例。当以下条件满足时，它将允许请求：

* 存在 JWT 令牌
* JWT 令牌未过期
* 你要访问的 URL 路径在 JWT 令牌中指定

创建一个名为 [s2s-policy.rego](../../../assets/howto/s2s-policy.rego) 的文件，其内容如下：

然后将策略存储在 Kubernetes 中作为 Secret。

```
kubectl create namespace httpbin
kubectl create secret generic opa-policy -n httpbin --from-file s2s-policy.rego
```

#### 创建带有 OPA 和 Envoy Sidecar 的 httpbin 部署

一旦你有了策略，就可以部署引用该策略的 `httpbin` 服务。
创建一个名为 [`s2s-httpbin-with-opa.yaml`](../../../assets/howto/s2s-httpbin-with-opa.yaml) 的文件，其内容如下：

然后使用 kubectl 应用它：

```
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
kubectl apply -n httpbin -f s2s-httpbin-with-opa.yaml
```

### 设置 `sleep` 服务

由于你将配置服务到服务授权，因此需要一个服务作为`httpbin`服务的客户端。

在本示例中，你将部署一个什么都不做的服务，该服务映射到上图中的"sleep 工作负载"。稍后你将使用 `kubectl exec` 发出 HTTP 请求到 `httpbin` 服务。

创建一个名为 [`s2s-sleep.yaml`](../../../assets/howto/s2s-sleep.yaml) 的文件，其内容如下：

使用 kubectl 部署此 sleep 服务：

```
kubectl create namespace sleep
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
kubectl apply -n sleep -f s2s-sleep.yaml
```

## 测试

### 禁用外部授权进行测试

到目前为止，你已经部署了服务，但尚未启用外部授权。因此，来自

`sleep`服务到`httpbin`服务的请求不会检查授权。

这可以通过检查是否从`sleep`服务发送的 HTTP 请求导致`200` OK 来看到。

要从 sleep 服务发送请求，请在`sleep`服务中确定要发送请求的 Pod：

```
export SLEEP_POD=$(kubectl get pod -n sleep -l app=sleep -o jsonpath={.items..metadata.name})
```

然后从此 Pod 发送请求到`httpbin`服务，应该可以在 `http://httpbin-with-opa.httpbin:8000` 处到达：

```bash
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/headers -s -o /dev/null -w "%{http_code}\n"
```

禁用外部授权时，上述命令应显示`200`。

### 启用外部授权进行测试

要查看外部授权的工作原理，你需要创建一个工作空间和安全组。

#### 创建工作空间

创建一个名为 [`s2s-workspace.yaml`](../../../assets/howto/s2s-workspace.yaml) 的文件，其内容如下。

请注意，在以下示例中，我们假设你已经使用 TSB 演示安装创建了名为`demo`的集群，并在其中部署了你的`httpbin`服务。如果你使用其他集群，请相应更改示例中的集群名称。

然后使用 tctl 应用它：

```
tctl apply -f s2s-workspace.yaml
```

#### 创建 SecuritySettings

一旦有了工作空间，你需要为该工作空间创建 SecuritySettings 以启用外部授权。

创建一个名为 [`s2s-security-settings.yaml`](../../../assets/howto/s2s-workspace.yaml) 的文件，其内容如下。

请注意，`uri` 指向本地地址 (`grpc://127.0.0.1:9191`)，因为在此示例中，OPA 服务部署在同一 Pod 中作为 Sidecar。如果你将 OPA 部署在单独的 Pod 中，你需要相应地更改 `uri` 的值。

然后使用 tctl 应用它：

```
tctl apply -f s2s-security-settings.yaml
```

### 测试授权

再次向 `httpbin` 服务发送请求。

使用已应用的 SecuritySettings，来自`sleep`服务到`httpbin`服务的普通请求应该失败，并显示`403` Forbidden。

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/headers -s -o /dev/null -w "%{http_code}\n"
```

上述命令应显示`403`。

为了授权请求，你需要在请求中添加 JWT。对于此示例，我们希望附加到请求的原始 JWT 如下所示：

```
{
  "path": "L2hlYWRlcnM=",
  "nbf": 1500000000,
  "exp": 1900000000
}
```

路径声明的值为 `L2hlYWRlcnM=`，这是字符串 `/headers` 的 Base64 编码形式。

JWT 需要通过 `Authorization` 标头传递，这需要整个 JWT 作为 Base64 编码，如下所示。将其保存到环境变量中：

```
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiTDJobFlXUmxjbk09IiwibmJmIjoxNTAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.9yl8LcZdq-5UpNLm0Hn0nnoBHXXAnK4e8RSl9vn6l98"
```

最后，使用上述 JWT 令牌向 `httpbin` 服务发送请求，确保请求指向与 JWT 中的声明匹配的路径 `/headers`。这次你应该收到 `200` OK。

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/headers -H "Authorization: Bearer $JWT_TOKEN" -s -o /dev/null -w "%{http_code}\n"
```

要检查其他路径的请求是否未经授权，请尝试发送以下请求，该请求指向路径 `/get`。以下命令应显示 `403` Forbidden。

```
kubectl exec ${SLEEP_POD} -n sleep -c sleep  -- curl http://httpbin-with-opa.httpbin:8000/get -H "Authorization: Bearer $JWT_TOKEN" -s -o /dev/null -w "%{http_code}\n"
```

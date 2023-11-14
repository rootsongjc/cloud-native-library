---
title: "使用 Envoy 和 X.509-SVID 进行 OPA 授权"
weight: 4
---

通过 Envoy 与 X.509-SVIDs 实现安全通信并结合 Open Policy Agent（OPA）进行授权。

[Open Policy Agent](https://www.openpolicyagent.org/)（OPA）是一个开源通用策略引擎，其提供的授权（AuthZ）是对 SPIRE 提供的认证（AuthN）的很好补充。

本教程将在 SPIRE Envoy-X.509 教程 的基础上添加 [Open Policy Agent](https://www.openpolicyagent.org/)（OPA）以演示如何将 SPIRE、Envoy 和 OPA 结合使用，实现 X.509 SVID 认证和请求授权。本教程将演示如何在现有教程的基础上实现使用 OPA 进行请求授权。

为了便于说明，让我们通过将 OPA 代理实例作为后端服务的新侧车来扩展 Envoy X.509 教程中创建的场景。借助 Envoy 的外部授权过滤器功能，结合 OPA 作为授权服务，可以实现对传入后端服务的每个请求执行安全策略。

![SPIRE Envoy OPA 集成图](../../images/SPIRE_Envoy_OPA_X509_diagram.png)

如图所示，前端服务通过 Envoy 实例连接到后端服务，Envoy 实例使用 SPIRE 代理提供的 SDS 模块进行身份验证，从而建立了 mTLS 连接。Envoy 通过 mTLS 连接将 HTTP 请求发送到后端，后端通过 OPA 代理实例根据安全策略对 HTTP 请求进行授权或拒绝。

在本教程中，你将学到：

- 将 OPA 代理添加到现有的 Envoy X.509 教程的后端服务中
- 将外部授权过滤器添加到将 Envoy 连接到 OPA 的 Envoy 配置中
- 使用 SPIRE 与 Envoy 进行 OPA 授权的测试

# 先决条件

在继续之前，请查看以下内容：

- 当通过 SPIRE Envoy-X.509 教程 进行配置时，你将需要访问 Kubernetes 环境。可选择使用 `pre-set-env.sh` 脚本创建 Kubernetes 环境。
- 本教程所需的 YAML 文件可以在 https://github.com/spiffe/spire-tutorials 的 `k8s/envoy-opa` 目录中找到。如果尚未克隆 spire-tutorials 存储库，请立即执行。

如果 Kubernetes 中的 *配置 Envoy 进行 X.509 SVID 认证* 教程环境不可用，你可以使用以下脚本创建该环境，并将其用作本教程的起点。从 `k8s/envoy-opa` 目录运行以下 Bash 脚本：

```bash
$ bash scripts/pre-set-env.sh
```

该脚本将创建集群中所需的所有 SPIRE 服务器和 SPIRE 代理资源，然后将为 SPIRE Envoy X.509 教程创建所有资源，该教程是 SPIRE Envoy 和 OPA 教程的基本场景。

**注意：** 本教程中所需的配置更改已显示为教程中的代码段。但是，所有这些设置已经配置好了。你无需编辑任何配置文件。

## 外部 IP 支持

本教程需要一个能够分配外部 IP（例如 [metallb](https://metallb.universe.tf/)）的负载均衡器。

```bash
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

等待 metallb 启动：

```bash
$ kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s
```

应用 metallb 配置：

```bash
$ kubectl apply -f ../envoy-x509/metallb-config.yaml
```

# 第一部分：部署更新和新资源

假设以 SPIRE Envoy X.509 教程为起点，需要更新一些资源并创建其他资源。目标是在请求到达 `backend` 服务之前，通过 OPA 让其进行授权。Envoy 实例之间已经建立了 mTLS 连接，因此唯一缺

失的部分是将 OPA 作为 sidecar 添加到部署中。可以通过以下方式将新容器添加到 [`backend-deployment.yaml`](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-opa/k8s/backend/backend-deployment.yaml) 中：

```yaml
- name: opa
  image: openpolicyagent/opa:0.50.2-envoy
  imagePullPolicy: IfNotPresent
  ports:
    - name: opa-envoy
      containerPort: 8182
      protocol: TCP
    - name: opa-api-port
      containerPort: 8181
      protocol: TCP
  args:
    - "run"
    - "--server"
    - "--config-file=/run/opa/opa-config.yaml"
    - "/run/opa/opa-policy.rego"
  volumeMounts:
    - name: backend-opa-policy
      mountPath: /run/opa
      readOnly: true
```

请注意使用了 `openpolicyagent/opa:0.50.2-envoy` 镜像。该镜像通过在 OPA 中扩展了一个实现 Envoy 外部授权 API 的 gRPC 服务器，以便 OPA 可以与 Envoy 通信以做出策略决策。

必须在 `volumes` 部分中添加 ConfigMap `backend-opa-policy`，如下所示：

```yaml
- name: backend-opa-policy
   configMap:
      name: backend-opa-policy-config
```

ConfigMap `backend-opa-policy` 提供了两个资源，分别是在 [OPA Configuration](https://spiffe.io/docs/latest/microservices/envoy-opa/readme/#opa-configuration) 中描述的 `opa-config.yaml` 和在 [Rego Policy](https://spiffe.io/docs/latest/microservices/envoy-opa/readme/#opa-policy) 部分中解释的 `opa-policy.rego`。

## OPA 配置

在本教程中，我们将在 [`opa-config.yaml`](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-opa/k8s/backend/config/opa-config.yaml) 中创建以下 OPA 配置文件：

```yaml
decision_logs:
   bash: true
plugins:
   envoy_ext_authz_grpc:
      addr: :8182
      query: data.envoy.authz.allow
```

在这里，`decision_logs.bash: true` 强制 OPA 在本地以 info 级别记录决策。稍后在教程中，我们将使用这些日志来检查不同请求的结果。

接下来，让我们来查看 `envoy_ext_authz_grpc` 插件的配置。首先，`addr` 键设置了 Envoy 外部授权 gRPC 服务器的监听地址。这必须与 Envoy 过滤器资源中配置的值相匹配，后面的章节将详细介绍。`query` 键定义了要查询的策略的名称。接下来的部分将重点介绍针对 `query` 键指定的 `envoy.authz.allow` 策略的详细信息。

## OPA 策略

OPA 策略以一种称为 Rego 的高级声明性语言表达。在本教程中，我们创建了一个名为 `allow` 的示例规则，其中包含三个表达式（参见 [`opa-policy.rego`](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-opa/k8s/backend/config/opa-policy.rego)）。为了使规则成立，所有表达式都必须为 true。

```
default allow = false

allow {
   valid_path
   http_request.method == "GET"
   svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend"
}
```

让我们逐个查看每个表达式。`valid_path` 是一个用户定义的函数，用于确保仅允许发送到允许资源的请求。

```
import input.attributes.request.http as http_request

valid_path {
   glob.match("/balances/*", [], http_request.path)
}

valid_path {
   glob.match("/profiles/*", [], http_request.path)
}

valid_path {
   glob.match("/transactions/*", [], http_request.path)
}
```

函数 `valid_path` 利用了内置函数 `glob.match(`_pattern_, _delimiters_, _match_`)`，其输出为 true，如果 _match_ 可以在以 _delimiters_ 分隔的 _pattern_ 中找到，然后在 Rego 中为了表示逻辑或，你定义具有相同名称的多个规则。这就是为什么有三个定义 `valid_path` 的规则，每个规则对应一个有效资源。

接下来的表达式定义了请求的 HTTP 方法必须等于 `GET`：

```
http_request.method == "GET"
```

最后一个表达式也是一个用户定义的函数：

```
svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend"
```

`svc_spiffe_id` 函数从请求中的 `x-forwarded-client-cert`（XFCC）头中提取服务的 SPIFFE ID。XFCC 头是一个代理头，指示请求已通过的某些或所有客户端或代理的证书信息。`svc_spiffe_id` 函数利用了来自 `envoy.yaml` 的两个 Envoy 设置，这些设置修改了 HTTP 头：

```
forward_client_cert_details: sanitize_set
set_current_client_cert_details:
   uri: true
```

当客户端连接为 mTLS 时，例如在此场景中，`forward_client_cert_details: sanitize_set` 会将 XFCC 头重置为客户端证书信息，`set_current_client_cert_details` 指定要转发的客户端证书中的字段。

XFCC 头值是一个以逗号（“,”）分隔的字符串。每个子字符串都是一个 XFCC 元素，每个 XFCC 元素都是一个以分号（“;”）分隔的字符串。每个子字符串都是一个键值对，由等号（“=”）组合在一起。Envoy 支持以下键：

- `By` 当前代理证书的主题可选名称（URI 类型）。
- `Hash` 当前客户端证书的 SHA 256 摘要。
- `Cert` 整个客户端证书的 URL 编码 PEM 格式。
- `Subject` 当前客户端证书的 Subject 字段。值总是被双引号引起来。
- `URI` 当前客户端证书的 URI 类型主题可选名称字段。
- `DNS` 当前客户端证书的 DNS 类型主题可选名称字段。客户端证书可能包含多个 DNS 类型的主题可选名称，每个都将是一个单独的键值对。

以下是带有示例值的 XFCC 头，为了便于阅读，该值分为两行：

```
x-forwarded-client-cert: By=spiffe://example.org/ns/default/sa/default/backend;Hash=a9317919875e178ce6d6
1eaa023490a2091299753ca5cd01d5323e40696d690b;URI=spiffe://example.org/ns/default/sa/default/frontend
```

在 `x-forwarded-client-cert` 头中，`Hash` 总是设置的，当客户端证书呈现 URI 类型的主题可选名称值时，`By` 也总是设置的，这在使用 X.509 SVIDs 时是真的。然后 `set_current_client_cert_details: uri: true` 确保了 URI 类型的主题可选名称（SAN）字段被转发。

了解了 XFCC 头的这些细节，并知道 X.509 SVID **必须** 包含一个 URI SAN，SPIFFE ID 设置为 SAN 扩展中的 URI 类型，那么就可以使用以下函数从 Envoy 设置的 XFCC 头中提取 SPIFFE ID：

```
svc_spiffe_id = spiffe_id {
   [_, _, uri_type_san] := split(http_request.headers["x-forwarded-client-cert"], ";")
   [_, spiffe_id] := split(uri_type_san, "=")
}
```

因此，只有当请求发送到有效的资源（/balances/，/profiles/ 或者 /transactions/）时，使用 `GET` 方法，并且请求来自 SPIFFE ID 等于 `spiffe://example.org/ns/default/sa/default/frontend` 的工作负载时，策略才会评估为真。在所有其他情况下，请求都不会被 OPA 授权，因此会被 Envoy 拒绝。

## 添加外部授权过滤器

最后，此设置需要添加一个连接到 OPA 实例的外部授权过滤器。这个新的 HTTP 过滤器与 OPA 一起作为授权服务使用，以通过 Envoy 接收的 API 请求来执行安全策略。这是通过在 `envoy.yaml` 中添加一个新的 HTTP 过滤器来实现的：

```yaml
- name: envoy.ext_authz
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
    transport_api_version: V3
    with_request_body:
      max_request_bytes: 8192
      allow_partial_message: true
    failure_mode_allow: false
    grpc_service:
      google_grpc:
        target_uri: 127.0.0.1:8182
        stat_prefix: ext_authz
      timeout: 0.5s
```

请注意，`target_uri` 配置为与前一步中定义的 OPA 服务通信。如果你感兴趣，完整的配置文件位于 [k8s/backend/config/envoy.yaml](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-opa/k8s/backend/config/envoy.yaml)。

## 应用新资源

为了使新配置生效，需要应用 OPA 配置的 ConfigMap，并更新 Envoy 配置。确保当前工作目录是 `.../spire-tutorials/k8s/envoy-opa`，并使用以下命令应用新配置：

```bash
$ kubectl apply -k k8s/.

configmap/backend-envoy configured
configmap/backend-opa-policy-config configured
deployment.apps/backend configured
```

接下来，需要重启 `backend` pod 以获取新配置：

```bash
$ kubectl scale deployment backend --replicas=0
$ kubectl scale deployment backend --replicas=1
```

# 第 2 部分：测试连接

现在，服务已经部署并在 SPIRE 中注册了，让我们测试一下我们已经配置的授权。

## 测试有效请求

第一个测试将演示满足策略的请求允许显示关联的数据。要运行此测试，我们需要找到构成用于访问数据的 URL 的 IP 地址和端口。

```bash
$ kubectl get services

NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)          AGE
backend-envoy   ClusterIP      None          <none>           9001/TCP         6m53s
frontend        LoadBalancer   10.8.14.117   35.222.164.221   3000:32586/TCP   6m52s
frontend-2      LoadBalancer   10.8.7.57     35.222.190.182   3002:32056/TCP   6m53s
kubernetes      ClusterIP      10.8.0.1      <none>           443/TCP          59m
```

`frontend` 服务将在 `EXTERNAL-IP` 值和端口 `3000` 上可用，这是我们为容器配置的。在上面显示的示例输出中，要导航到的 URL 是 `http://35.222.164.221:3000`。打开浏览器，导航到环境中显示的 `frontend` 的 IP 地址，添加端口 `:3000`。一旦页面加载，你将看到用户 *Jacob Marley* 的账户详细信息。

![前端视图](../../images/frontend_view.png)

让我们看一下 OPA 代理的日志，看看后台正在发生什么。使用以下 Bash 脚本获取运行在 `backend` 服务旁边的 OPA 实例的日志，并使用 `[jq](<https://stedolan.github.io/jq/>)` 处理输出：

```bash
$ bash scripts/backend-opa-logs.sh
```

输出显示了每个请求的决定。例如，对 `frontend` 服务的请求可能会产生类似于以下的日志条目：

```json
{
  "decision_id": "207b7b54-0ec0-4ffb-a531-c86a9f05c38d",
  "input": {
    "attributes": {
      ...
      "request": {
        "http": {
          "headers": {
            ":authority": "localhost:3003",
            ":method": "GET",
            ":path": "/profiles/2",
            "accept-encoding": "gzip",
            "content-length": "0",
            "user-agent": "Go-http-client/1.1",
            "x-forwarded-client-cert": "By=spiffe://example.org/ns/default/sa/default/backend;Hash=a9317919875e178ce6d61eaa023490a2091299753ca5cd01d5323e40696d690b;URI=spiffe://example.org/ns/default/sa/default/frontend",
            "x-forwarded-proto": "http",
            "x-request-id": "e0939bcf-8beb-4910-a980-be0468ec023f"
          },
          "method": "GET",
          "path": "/profiles/2",
          "protocol": "HTTP/1.1"
        },
      ...
      },
      ...
    },
   ...
  },

  "msg": "Decision Log",
  "query": "data.envoy.authz.allow",
  "requested_by": "",
  "result": true,
  "time": "2020-06-11T18:58:47Z",
  "timestamp": "2020-06-11T18:58:47.840319148Z",
  "type": "openpolicyagent.org/decision_logs"
}
```

在这种情况下，OPA `result` 决定为真，意味着请求被允许通过过滤器并到达 `backend` 服务，因为满足了 `opa-policy.rego` Rego 策略中定义的所有以下条件：

- 从 `x-forwarded-client-cert`（XFCC）头中提取的 SPIFFE ID URI 匹配预期的 SPIFFE ID：`spiffe://example.org/ns/default/sa/default/frontend`
- 请求的路径匹配：`/profiles/2`
- HTTP 方法匹配：`GET`

## 测试无效请求

另一方面，按照相同的步骤，我们可以确认不满足策略的请求阻止了相关数据的显示。在此情况下，`frontend-2`服务无法与`backend`服务通信，因为其 SPIFFE ID 不满足 OPA Agent 的策略。因此，当你连接到`frontend-2`服务的 URL（例如`http://35.222.190.182:3002`），浏览器只显示标题，没有任何帐户详细信息。

![浏览器视图](../../images/frontend-2_view_no_details.png)

尝试显示`frontend-2`数据后，你可以使用与上一节相同的`scripts/backend-opa-logs.sh`脚本来验证 OPA 做出的决定。由于 SPIFFE ID 不匹配，`frontend-2`服务有类似的日志条目，但结果等于`false`。

## 使用新策略重新测试 frontend-2

让我们更新 Rego 策略以匹配`frontend-2`的 SPIFFE ID，然后再进行测试。我们可以利用一个 Bash 脚本来完成这个任务。执行后，它将打开由你的`KUBE_EDITOR`或`EDITOR`环境变量定义的编辑器，或者在 Linux 上回退到`vi`，在 Windows 上回退到 Notepad。

```bash
$ bash scripts/backend-update-policy.sh
```

打开编辑器后，寻找指定 SPIFFE ID 的以下行：

```
svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend"
```

更新该行以匹配`frontend-2`工作负载的 SPIFFE ID：

```
svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend-2"
```

保存更改并退出。`backend-update-policy.sh`脚本恢复。该脚本应用 ConfigMap 的新版本，然后重新启动`backend`pod 以获取新的规则。等待几秒钟，等待部署传播，然后再尝试在浏览器中查看`frontend-2`服务。一旦 pod 准备就绪，刷新浏览器，使用`frontend-2`服务的正确 URL（例如`http://35.222.190.182:3002`）。结果，现在页面显示了用户*Alex Fergus*的帐户详细信息。

另一方面，如果你现在连接到`frontend`服务的 URL（例如`http://35.222.164.221:3000`），浏览器只显示标题，没有任何帐户详细信息。这是预期的行为，因为策略已经更新，现在`frontend`服务的 SPIFFE ID 不再满足策略。

# 清理

当你完成时，你可以使用以下命令清理为教程创建的环境。它将删除：

- 为此 SPIRE - Envoy 与 OPA 集成教程创建的所有资源
- 为 SPIRE - Envoy X.509 集成教程创建的所有资源
- SPIRE Agent，SPIRE Server 和命名空间的所有部署和配置

```bash
$ bash scripts/clean-env.sh
```
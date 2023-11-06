---
title: 使用 Envoy 和 JWT-SVIDs 进行 OPA 授权
weight: 5
---

本文指导你如何使用 Envoy 和 JWT-SVIDs 以及开放策略代理进行安全通信。

[开放策略代理](https://www.openpolicyagent.org/)（OPA）是一个开源的、通用的策略引擎。OPA 提供的授权（AuthZ）可以很好地补充 SPIRE 提供的认证（AuthN）。

本教程基于[SPIRE Envoy-JWT 教程](https://github.com/spiffe/spire-tutorials/blob/main/envoy-jwt/README.md)，演示如何结合 SPIRE、Envoy 和 OPA 进行 JWT SVID 认证和请求授权。实现 OPA 请求授权所需的更改在本教程中以增量形式展示，因此你应先运行或至少阅读 SPIRE Envoy-JWT 教程。

![架构图](../../images/SPIRE-Envoy_JWT_OPA_diagram.png)

为了说明如何使用 OPA 进行请求授权，我们在 SPIRE Envoy JWT 教程中使用的后端服务中添加了一个新的 sidecar。新的 sidecar 充当 Envoy 的新[外部授权过滤器](https://www.envoyproxy.io/docs/envoy/v1.25.1/intro/arch_overview/security/ext_authz_filter#arch-overview-ext-authz)。

如图所示，前端服务通过由 Envoy 实例建立的 mTLS 连接连接到后端服务。Envoy 通过 mTLS 连接发送 HTTP 请求，其中携带了用于认证的 JWT-SVID。JWT-SVID 由 SPIRE Agent 提供并验证，然后，请求会根据安全策略由 OPA Agent 实例授权或拒绝。

在本教程中，你将学习如何：

- 将 OPA Agent 添加到 SPIRE Envoy JWT 教程中现有的后端服务
- 在连接 Envoy 到 OPA 的 Envoy 配置中添加一个外部授权过滤器
- 测试成功的使用 SPIRE 和 OPA 授权的 JWT 认证

# 先决条件

## 外部 IP 支持

本教程需要一个负载均衡器，该负载均衡器能够分配外部 IP（例如，[metallb](https://metallb.universe.tf/)）

```bash
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
```

等到 metallb 启动

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

## 授权助手镜像

使用[Envoy-jwt-auth-helper](https://github.com/spiffe/spire-tutorials/blob/main/envoy-jwt-auth-helper)实现了一个外部授权过滤器，提供了一个脚本来简化使用`kind`或`minikube`的构建和导入

```bash
$ bash ./scripts/build-helper.sh kind
```

## 之前的 SPIRE 安装

在开始之前，回顾以下内容：

- 你需要访问在完成 [SPIRE Envoy-JWT 教程](https://github.com/spiffe/spire-tutorials/blob/main/envoy-jwt/README.md)时配置的 Kubernetes 环境。或者，你可以使用下面描述的`pre-set-env.sh`脚本创建 Kubernetes 环境。
- 此教程所需的 YAML 文件可以在  <https://github.com/spiffe/spire-tutorials> 的 `k8s/envoy-jwt-opa` 目录中找到。如果你还没有克隆 spire-tutorials 存储库，请立即这样做。

如果 Kubernetes *配置 Envoy 以执行 JWT SVID 身份验证*教程环境不可用，你可以使用以下脚本创建它，并将它用作本教程的起点。从`k8s/envoy-jwt-opa`目录中，运行以下 Bash 脚本：

```bash
$ bash scripts/pre-set-env.sh
```

该脚本将创建 SPIRE 服务器和 SPIRE 代理在集群中可用所需的所有资源，然后将为 SPIRE Envoy JWT 教程创建所有资源，这是此 SPIRE Envoy JWT 与 OPA 教程的基础场景。

注意：本教程中显示的配置更改需要使 Envoy 和 OPA 与 SPIRE 一起工作。但是，所有这些设置已经配置好了。你不需要编辑任何配置文件。

# 第一部分：部署更新和新资源

假定 SPIRE Envoy JWT 教程为起点，需要创建一些资源。目标是在请求到达`backend`服务之前，由 OPA 代理对其进行授权。在 Envoy 实例之间建立了 mTLS 连接，其中 JWT SVID 在请求中作为`authorization`头部传输。因此，缺少的部分是添加一个 OPA 代理以根据策略对请求进行授权。在本教程中应用的解决方案包括向运行在`backend`服务前的 Envoy 实例添加新的外部授权过滤器。新的过滤器在请求通过 Envoy JWT Auth Helper（第一个过滤器）之后调用 OPA 代理，其作用是检查是否应授权或拒绝请求。

## 更新部署

为了让 OPA 授权或拒绝发送到`backend`服务的请求，我们需要将 OPA 添加为部署的 sidecar。我们使用`openpolicyagent/opa:0.50.2-envoy`镜像，该镜像扩展了 OPA 并添加了一个实现 Envoy 外部授权 API 的 gRPC 服务器，因此 OPA 可以与 Envoy 通信策略决策。在 [`backend-deployment.yaml`](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-jwt-opa/k8s/backend/backend-deployment.yaml)中，添加并配置新的容器，如下所示：

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

需要将`backend-opa-policy` ConfigMap 添加到`volumes`部分，如下所示：

```yaml
- name: backend-opa-policy
  configMap:
    name: backend-opa-policy-config
```

`backend-opa-policy` ConfigMap 提供了两个资源，`opa-config.yaml`在[OPA 配置](https://spiffe.io/docs/latest/microservices/envoy-jwt-opa/readme/#opa-configuration)中描述，而`opa-policy.rego`策略在[OPA 策略](https://spiffe.io/docs/latest/microservices/envoy-jwt-opa/readme/#opa-policy)部分解释。

## OPA 配置

对于本教程，我们在 [`opa-config.yaml`](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-jwt-opa/k8s/backend/config/opa-config.yaml) 中创建了以下 OPA 配置文件：

```yaml
decision_logs:
   console: true
plugins:
   envoy_ext_authz_grpc:
      addr: :8182
      query: data.envoy.authz.allow
```

选项`decision_logs.console: true`强制 OPA 将决策在控制台上以信息级别本地记录。稍后在教程中，我们将使用这些日志来检查不同请求的结果。

接下来，让我们回顾一下`envoy_ext_authz_grpc`插件的配置。`addr`键设置实现 Envoy 外部授权 API 的 gRPC 服务器的监听地址。这必须与接下来的部分中详细描述的 Envoy 过滤器资源中配置的值匹配。`query`键定义要查询的策略决策的名称。下一部分将关注为`query`键指定的`envoy.authz.allow`策略的细节。

## OPA 策略

OPA 政策使用高级声明性语言 Rego 表达。对于本教程，我们创建了一个名为`allow`的样本规则，该规则包含三个表达式（请参见 [`opa-policy.rego`](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-jwt-opa/k8s/backend/config/opa-policy.rego)）。所有表达式必须为真，该规则才为真。

```
package envoy.authz

default allow = false

allow {
    valid_path
    http_request.method == "GET"
    svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend"
}
```

让我们逐一查看每个表达式。`valid_path`是一个用户定义的函数，用于确保只允许发送给允许的资源的请求。

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

函数`valid_path`利用内置函数`glob.match(` *pattern, delimiters, match*`)`的输出，如果在由*delimiters*分隔的*pattern*中可以找到*match*，则其输出为真。然后，要在 Rego 中表示逻辑 OR，你需要定义具有相同名称的多个规则。这就是为什么`valid_path`有三个定义，每个有效资源一个。

以下表达式定义了请求的 HTTP 方法必须等于`GET`:

```
http_request.method == "GET"
```

最后一个表达式也对应于一个用户定义的函数，只有当 JWT-SVID 中编码的 SPIFFE ID 等于分配给`frontend`服务的 SPIFFE ID 时，该函数才会为真。

```
svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend"
```

函数`svc_spiffe_id`从请求中的`authorization`头中提取服务的 SPIFFE ID。因为请求已经通过了第一个 Envoy 筛选器（以验证模式运行的 Envoy JWT Auth Helper），我们知道它有一个有效的 JWT，我们可以解码来提取调用服务的 SPIFFE ID。OPA 提供了一个处理 JWT 的特殊代码，我们可以利用它来解码 JWT 并提取 SPIFFE ID：

```
svc_spiffe_id = payload.sub {
   [_, encoded_token] := split(http_request.headers.authorization, " ")
   [_, payload, _] := io.jwt.decode(encoded_token)
}
```

因此，只有当请求被发送到一个有效的资源（/balances/，/profiles/或/transactions/）并且请求的方法为`GET`，且请求来自一个用等于 `spiffe://example.org/ns/default/sa/default/frontend` 的 SPIFFE ID 认证的工作负载时，策略才会评估为真。在所有其他情况下，请求都不会被 OPA 授权，因此会被 Envoy 拒绝。

## 在 Envoy 中添加一个新的外部授权过滤器

Envoy 需要知道如何联系刚刚配置的 OPA Agent，以执行每个请求的授权。为了完成设置，我们在[Envoy 配置](https://github.com/spiffe/spire-tutorials/blob/main/k8s/envoy-jwt-opa/k8s/backend/config/envoy.yaml)的`http_filters`部分添加一个类型为 External Authorization Filter 的新过滤器，如下所示：

```yaml
- name: envoy.filters.http.ext_authz
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
    with_request_body:
      max_request_bytes: 8192
      allow_partial_message: true
   failure_mode_allow: false
   transport_api_version: V3
   grpc_service:
      google_grpc:
        target_uri: 127.0.0.1:8182
        stat_prefix: ext_authz
      timeout: 0.5s
```

该配置告诉 Envoy 联系 OPA Agent，地址为 127.0.0.1，端口为 8182。这与在[OPA 配置](https://spiffe.io/docs/latest/microservices/envoy-jwt-opa/readme/#opa-configuration)部分解释的 OPA 配置相匹配。

## 应用新资源

确保当前的工作目录是`.../spire-tutorials/k8s/envoy-jwt-opa`，并使用以下命令部署新资源：

```bash
$ kubectl apply -k k8s/.

configmap/backend-envoy configured
configmap/backend-opa-policy-config created
deployment.apps/backend configured
```

为了使新配置生效，需要重启`backend`服务。运行以下两个命令来强制重启：

```bash
$ kubectl scale deployment backend --replicas=0
$ kubectl scale deployment backend --replicas=1
```

# 第二部分：测试连接

现在服务已经更新和部署，让我们测试我们已经配置的授权。

## 测试有效请求

第一个测试将演示如何允许满足策略的请求显示关联数据。为了运行这个测试，我们需要找到组成用于访问数据的 URL 的 IP 地址和端口。

```bash
$ kubectl get services

NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)          AGE
backend-envoy   ClusterIP      None            <none>           9001/TCP         5m56s
frontend        LoadBalancer   10.96.194.108   172.18.255.200   3000:30824/TCP   5m56s
frontend-2      LoadBalancer   10.96.61.216    172.18.255.201   3002:31960/TCP   5m56s
kubernetes      ClusterIP      10.96.0.1       <none>           443/TCP          14m
```

`frontend`服务将在`EXTERNAL-IP`值和端口`3000`处可用，这是我们为容器配置的。在上面显示的示例输出中，导航到的 URL 是`http://172.18.255.200:3000`。打开浏览器，并导航到你的环境中显示为`frontend`的 IP 地址，添加端口`:3000`。一旦页面加载，你将看到用户*Jacob Marley*的账户详情。

![前端](../../images/frontend_view.png)

让我们看看 OPA Agent 的日志，看看幕后发生了什么。使用以下 Bash 脚本获取运行在`backend`服务旁的 OPA 实例的日志，并使用 [jq](https://stedolan.github.io/jq/) 处理输出：

```bash
$ bash scripts/backend-opa-logs.sh
```

输出显示了每个请求的决策。例如，对`frontend`服务的请求可能会产生类似于以下的日志条目：

```json
{
  "decision_id": "96ed5a6c-c2d3-493a-bdd2-bf8b94036bfb",
  "input": {
    "attributes": {
      ...
      "request": {
        "http": {
          "headers": {
            ":authority": "localhost:3001",
            ":method": "GET",
            ":path": "/transactions/1",
            "accept-encoding": "gzip",
            "authorization": "Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImU2d3JsNkw3Nm5HS3VVVDlJdVhoVEpFbFVIaExSZFJrIiwidHlwIjoiSldUIn0.eyJhdWQiOlsic3BpZmZlOi8vZXhhbXBsZS5vcmcvbnMvZGVmYXVsdC9zYS9kZWZhdWx0L2JhY2tlbmQiXSwiZXhwIjoxNTk0MjM5NzQ3LCJpYXQiOjE1OTQyMzk0NDcsInN1YiI6InNwaWZmZTovL2V4YW1wbGUub3JnL25zL2RlZmF1bHQvc2EvZGVmYXVsdC9mcm9udGVuZCJ9.YiS52Y44iOGgaRPcXmhm_FRHgjGIPknx3HqHvVsQNiQw4uJx3eICPECQqTpFOh3flEqvDizlpehipHHdhKEy8TvZtJRnPQ69Jofce4aCx5wF0KQtOBZ79bx9H0Y0gcWWzIDb3YW3uNVfZnHvojlLnzqJb3axIhAqgNbURmlm4STTISxJxNzYcr24Zio6uTYSEJmLtQlFVShhUUQr0zFyj_tbyc9RRcX3MNWLFrkWS8eVIQvkvKBO2zYt2FA0GACBnSFDcR6u2G-5QCU7mzlOnqCrMZ6q4aaRp86v33fYbKZKSfghfcmAeOKc-aai92sTlSPSpWnv5qLKIs6GpT6H7A",
            "content-length": "0",
            "user-agent": "Go-http-client/1.1",
            "x-forwarded-proto": "http",
            "x-request-id": "fad45df6-3cc1-4ce9-9cad-fb3b65eff037"
          },
          "host": "localhost:3001",
          "id": "10476077497628160603",
          "method": "GET",
          "path": "/transactions/1",
          "protocol": "HTTP/1.1"
        },
      ...
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
  "time": "2020-07-08T20:17:27Z",
  "timestamp": "2020-07-08T20:17:27.7568234Z",
  "type": "openpolicyagent.org/decision_logs"
}
```

注意 `authorization` 头中包含了 JWT。如 [OPA 策略](https://spiffe.io/docs/latest/microservices/envoy-jwt-opa/readme/#opa-policy) 部分所解释的，这个 JWT 使用 OPA 提供的专用代码进行解码，然后提取 SPIFFE ID。我们已经知道，`frontend` 服务的 SPIFFE ID 与为 OPA Agent 配置的 Rego 策略中定义的 SPIFFE ID 匹配。此外，请求的路径和方法也匹配规则，所以决策的 `result` 为 `true`，请求被允许通过过滤器并到达 `backend` 服务。

## 测试无效的请求

另一方面，当你连接到 `frontend-2` 服务的 URL (例如 `http://172.18.255.201:3002`) 时，浏览器只显示标题，没有任何账户详情。这是因为 `frontend-2` 服务的 SPIFFE ID（`spiffe://example.org/ns/default/sa/default/frontend-2`）不满足 OPA Agent 的策略。

![](../../images/frontend-2_view_no_details.png)

在尝试显示 `frontend-2` 数据后，你可以使用与前一节中执行的相同的 `scripts/backend-opa-logs.sh` 脚本来验证 OPA 做出的决定。对于 `frontend-2` 服务，有一个类似的日志条目，但是由于 SPIFFE ID 不匹配，`result` 等于 `false`。

## 用新策略重新测试 frontend-2

让我们更新 Rego 策略以匹配 `frontend-2` 服务的 SPIFFE ID，然后再测试。你可以利用一个 Bash 脚本来完成这个任务。一旦执行，它会打开你的 `KUBE_EDITOR` 或 `EDITOR` 环境变量定义的编辑器，或者回退到 Linux 的 `vi` 或 Windows 的 Notepad。

```bash
$ bash scripts/backend-update-policy.sh
```

打开编辑器后，寻找指定规则要匹配的 SPIFFE ID 的以下行：

```
svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend"
```

更新该行以匹配 `frontend-2` 服务的 SPIFFE ID：

```
svc_spiffe_id == "spiffe://example.org/ns/default/sa/default/frontend-2"
```

保存更改并退出。`backend-update-policy.sh` 脚本恢复。该脚本应用 ConfigMap 的新版本，然后重启 `backend` pod 以获取新规则。在尝试再次在浏览器中查看 `frontend-2` 服务之前，等待一些秒钟以便部署传播。一旦 pod 准备好，刷新使用 `frontend-2` 服务的正确 URL（例如 `http://172.18.255.201:3002`）的浏览器。结果，现在页面显示了用户 *Alex Fergus* 的帐户详细信息。

![](../../images/frontend-2_view.png)

另一方面，如果你现在连接到 `frontend` 服务的 URL（例如 `http://172.18.255.200:3000`），浏览器只显示标题，没有任何账户详情。这是预期的行为，因为策略已经更新，现在 `frontend` 服务的 SPIFFE ID 不再满足策略。

# 清理

当你完成后，你可以使用以下命令清理为教程创建的环境。它将移除：

- 为这个 SPIRE - Envoy JWT 与 OPA 集成教程创建的所有资源
- 为 SPIRE - Envoy JWT 集成教程创建的所有资源
- SPIRE Agent、SPIRE Server 和命名空间的所有部署和配置

```bash
$ bash scripts/clean-env.sh
```

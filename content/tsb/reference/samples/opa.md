---
title: 安装 Open Policy Agent
weight: 2
---

[Open Policy Agent](https://www.openpolicyagent.org/) (OPA) 是一个开源的通用策略引擎，提供了一种高级声明性语言，允许您将策略定义为代码。OPA 还提供了简单的 API，用于从您的软件中卸载策略决策。

本文档描述了在 TSB 中配置 OPA 的简化版本，以配合使用它作为外部授权 (`ext-authz`) 服务的部分，您的实际应用程序可能存在需要进行调整的差异。

{{<callout note "OPA 支持">}}
Tetrate 不提供对 OPA 的支持。如果您需要支持，请在其他地方寻找。
{{</callout>}}

有关下面所述的配置的更详细解释，请参考[官方文档](https://www.openpolicyagent.org/docs/latest)。

## 准备策略

OPA 需要使用[OPA 的策略语言](https://www.openpolicyagent.org/docs/latest/policy-language/)编写策略文件以决定是否应授权请求。由于实际策略将因示例而异，因此本文档不会涵盖如何编写此文件的详细信息。请参考[OPA 网站上的文档](https://www.openpolicyagent.org/docs/latest)以获取详细信息。

需要注意的一点是策略文件中指定的包名称。如果您的策略文件具有以下包声明，您将在稍后的容器配置中使用值 `helloworld.authz`。

```
package helloworld.authz
```

### 示例：具有基本身份验证的策略

此示例显示了一个策略，仅允许用户 `alice` 和 `bob` 通过基本身份验证进行身份验证。如果用户被授权，用户名称将存储在名为 `x-user` 的 HTTP 标头中。

```
package example.basicauth

default allow = false

# 用户名和密码数据库
user_passwords = {
    "alice": "password",
    "bob": "password"
}

allow = response {
    # 检查标头中的密码是否与特定用户的数据库中的密码相同
    basic_auth.password == user_passwords[basic_auth.user_name]
    response := {
      "allowed": true,
      "headers": {"x-user": basic_auth.user_name}
    }
}

basic_auth := {"user_name": user_name, "password": password} {
    v := input.attributes.request.http.headers.authorization
    startswith(v, "Basic ")
    s := substring(v, count("Basic "), -1)
    [user_name, password] := split(base64url.decode(s), ":")
}
```

### 将策略存储在 Kubernetes 中

假设您的策略存储在名为 `policy.rego` 的文件中，您需要将文件存储在 Kubernetes 的 Secret 或 ConfigMap 中。

要创建一个 Secret，请执行以下命令，将 `namespace` 替换为适当的值：

```bash
kubectl create secret generic opa-policy -n <namespace> \
  --from-file policy.rego
```

如果使用 ConfigMap，请以相同的方式执行以下命令：

```bash
kubectl create configmap opa-policy -n <namespace> \
  --from-file policy.rego
```

资源的名称（`opa-policy`）可以根据需要更改。

## 基本部署

以下清单显示了一个示例，可用于部署一个 OPA 服务和大部分默认设置的 OPA 代理。请记住将配置中的 `package` 和 `namespace` 替换为正确的值。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: <namespace>
spec:
  selector:
    app: opa
  ports:
    - name: grpc
      protocol: TCP
      port: 9191
      targetPort: 9191
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: opa
  namespace: <namespace>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
      name: opa
    spec:
      volumes:
        - name: opa-policy
          secrets:
            secretName: opa-policy
      containers:
        image: openpolicyagent/opa:latest-envoy
        name: opa
        securityContext:
          runAsUser: 1111
        args:
          - "run"
          - "--server"
          - "--addr=localhost:8181"
          - "--diagnostic-addr=0.0.0.0:8282"
          - "--set=plugins.envoy_ext_authz_grpc.addr

=:9191"
          - "--set=plugins.envoy_ext_authz_grpc.query=data.<package>.allow"
          - "--set=decision_logs.console=true"
          - "--ignore=.*"
          - "/policy/policy.rego"
        livenessProbe:
          httpGet:
            path: /health?plugins
            scheme: HTTP
            port: 8282
          initialDelaySeconds: 5
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health?plugins
            scheme: HTTP
            port: 8282
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - readOnly: true
          mountPath: /policy
          name: opa-policy
```

假设您已将上述清单保存在名为 `opa.yaml` 的文件中，请执行以下命令进行部署：

```bash
kubectl apply -f opa.yaml
```

## 终止 TLS

为了保障 ext-authz 服务（我们在这里使用 OPA 作为示例）与其客户端（网关和 sidecar）之间的通信，您可以启用 TLS 验证。作为示例，在这里我们将使用 Envoy sidecar 代理来终止 TLS 并验证来自客户端的 TLS 证书。

{{<callout note "注意">}}
以下示例中的设置仅用于测试目的。请根据您的生产用例的安全需求进行不同配置。
{{</callout>}}

### 准备证书

可以使用管理员提供的证书，也可以使用自签名证书进行测试。您可以利用[快速入门指南中的说明](../../../quickstart/ingress-gateway)创建自签名证书。

如果您尚未这样做，请创建一个包含证书的 Secret。Secret 将命名为 `opa-certs`，稍后将使用它。假设您已生成了文件 `opa.key` 和 `opa.crt`，请执行以下命令创建 Secret。将 `namespace` 的值替换为适当的值。

```bash
kubectl -n <namespace> create secret tls opa-certs \
  --key opa.key \
  --cert opa.crt
```

### 创建 Envoy 配置文件

创建一个名为 `config.yaml` 的文件，具有以下内容。将 `namespace` 的值替换为适当的值。此配置假定管理员端口位于端口 `10250`，端口 `18080` 上有一个 "不安全" 的 `grpc`，端口 `18443` 上有一个带 TLS 终止的 `grpc`。

```yaml
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 10250

static_resources:
  listeners:
    # 不安全的 GRPC 监听器
    - name: grpc-insecure
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 18080
      access_log:
        - name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                cluster: grpc_rlserver
                stat_prefix: grpc_insecure

    # 通过 TLS 进行安全保护
    - name: grpc-simple-tls
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 18443
      access_log:
        - name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                cluster: grpc_rlserver
                stat_prefix: grpc_simple_tls
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
              common_tls_context:
                tls_certificates:
                  - certificate_chain: { filename: /certs/tls.crt }
                    private_key: { filename: /certs/tls.key }
```

创建一个 `ConfigMap`，将配置存储在 Kubernetes 中。将 `namespace` 的值替换为适当的值。

```bash
kubectl create configmap -n <namespace> opa-proxy \
  --from-file=config.yaml
```

### 部署服务

创建一个名为 `opa-tls.yaml` 的文件，具有以下内容。将 `namespace` 的值替换为适当的值。

```yaml
apiVersion: v1
kind: Service
metadata:
 name: opa-tls
 namespace: <namespace>
spec:
 selector:
   app: opa-tls
 ports:
   - name: http
     port: 8080
     targetPort: 8080 # Doesn't go through Envoy
   - name: grpc-insecure
     port: 18080
     targetPort: 18080
   - name: grpc-tls
     port: 18443
     targetPort: 18443
---
apiVersion: apps/v1
kind: Deployment
metadata:
 name: opa-tls
 namespace: <namespace>
spec:
 replicas: 1
 selector:
   matchLabels:
     app: opa-tls
 template:
   metadata:
     labels:
       app: opa-tls
     name: opa-tls
   spec:
     containers:
     - name: envoy-proxy
       image: envoyproxy/envoy-alpine:v1.18.4
       imagePullPolicy: Always
       command:
         - "/usr/local/bin/envoy"
       args:
         - "--config-path /etc/envoy/config.yaml"
         - "--mode serve"
       ports:
       - name: grpc-plaintext
         containerPort: 18080
       - name: grpc-tls
         containerPort: 18443
       volumeMounts:
         - name: proxy-config
           mountPath: /etc/envoy
         - name: proxy-certs
           mountPath: /certs
     - name: opa
       image: openpolicyagent/opa:latest-envoy
       securityContext:
         runAsUser: 1111
       ports:
       - containerPort: 8181
       args:
       - "run"
       - "--server"
       - "--addr=localhost:8181"
       - "--diagnostic-addr=0.0.0.0:8282"
       - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
       - "--set=plugins.envoy_ext_authz_grpc.path=demo/authz/allow"
       - "--set=decision_logs.console=true"
       - "--ignore=.*"
       - "/policy/policy.rego"
       livenessProbe:
         httpGet:
           path: /health?plugins
           scheme: HTTP
           port: 8282
         initialDelaySeconds: 5
         periodSeconds: 5
       readinessProbe:
         httpGet:
           path: /health?plugins
           scheme: HTTP
           port: 8282
         initialDelaySeconds: 5
         periodSeconds: 5
       volumeMounts:
         - readOnly: true
           mountPath: /policy
           name: opa-policy
     volumes:
     - name: opa-policy
       configMap:
         name: opa-policy
     - name: proxy-certs
       secret:
         secretName: opa-certs
     - name: proxy-config
       configMap:
        name: opa-proxy
```



使用以下命令使用 kubectl 应用 `opa-tls.yaml`：

```bash
kubectl apply -f opa-tls.yaml
```

一旦上述部署准备好，您应该适当地设置客户端端以使用 `grpcs://opa-tls.<namespace>.svc.cluster.local:18443`。
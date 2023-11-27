---
title: 配置日志级别
description: 配置 TSB 组件的日志级别。
weight: 7
---

本文档介绍了如何在 TSB 中调整不同组件的日志级别，包括平台组件、Envoy Sidecar 和入口网关的运行时，以及查看日志的过程。

在开始之前，请确保：

- 你已正确安装和配置了 TSB。
- 你已安装和配置了`kubectl`以访问应用程序集群。

对于示例命令，我们假设你在`helloworld`命名空间中部署了一些应用程序。

{{<callout warning "TSB 组件产生大量日志">}}
小心在较长时间内启用 TSB 的各个范围的调试日志 - TSB 组件产生大量日志！由于自动日志摄取与 TSB 或 Sidecar 的日志级别提高相结合，可能会面临大额的日志摄取费用。
{{</callout>}}

## 列出可用的组件

为了更改每个组件的日志级别，你需要知道哪些组件可用。为此，在`tctl`中有一个实用命令，它将利用当前的`kubectl`连接信息（上下文）并列出该集群中可用的组件。

```bash
$ tctl experimental debug list-components 
PLANE         COMPONENT                 DEPLOYMENTS                           
management    ldap                      ldap                                     
management    mpc                       mpc                                      
management    xcp                       central, xcp-operator-central            
management    frontenvoy                envoy                                    
management    iamserver                 iam                                      
management    apiserver                 tsb                                      
management    tsb-operator              tsb-operator-management-plane            
management    web-ui                    web                                      
management    zipkin                    zipkin                                   
management    oap                       oap                                      
management    collector                 otel-collector                           
management    postgres                  postgres                                 
control       istio                     istio-operator                           
control       hpaadapter                istio-system-custom-metrics-apiserver    
control       oap                       oap-deployment                           
control       onboarding                onboarding-operator                      
control       collector                 otel-collector                           
control       tsb-operator              tsb-operator-control-plane               
control       zipkin                    zipkin                                   
control       xcp                       edge, xcp-operator-edge                  
data          operator                  istio-operator                           
data          tsb-operator              tsb-operator-data-plane                  
data          bookinfo-gateway          bookinfo/bookinfo-gateway                
data          helloworld-tls-gateway    helloworld-tls/helloworld-tls-gateway    
data          helloworld-gateway        helloworld/helloworld-gateway            
data          httpbin-gateway           httpbin/httpbin-gateway                  
data          tier1                     tier1/tier1
```

如上所示，此命令将列出集群中的所有可用组件，并按平面（管理、控制或数据平面）对其进行排序。它还将显示构建每个组件的 Kubernetes 部署。输出中的`PLANE`和`COMPONENT`列是下面用于设置日志级别的命令中需要使用的内容。例如，要更改`mpc`组件的日志级别，你需要使用`management/mpc`来引用它。

## TSB 平台组件（管理和控制平面）

TSB 组件能够在不重新启动 Pod 的情况下在运行时调整不同现有记录器的日志级别。为此，已添加了`tctl` CLI 中的新命令。

为了检查组件的可用记录器以及检查当前级别，运行不带任何标志的命令。

```bash
tctl experimental debug log-level management/iamserver
配置日志级别：
    POST /logging?level=value	  -> 配置全局级别
    POST /logging?logger=value	  -> 配置'logger'的日志级别

当前的日志级别：

admin                info    管理服务器日志
auth                 info    认证消息服务器
config               info    来自配置系统的消息
credentials/basic    info    基本HTTP凭证解析提供程序
credentials/jwt      info    JWT负载凭证解析提供程序
default              info    无作用域的日志消息。
dynadsn              info    来自动态数据库连接池的消息
envoy-filter         info    Envoy过滤器消息
exchange             info    令牌交换消息
grpc                 info    来自gRPC层的消息
health               info    健康检查服务的消息
iam-server           info    RunGroup处理程序的消息
iam/http             info    来自http服务器的消息
jwt                  info    LDAP提供程序的消息
keyvalue/tx          info    事务系统的消息
ldap                 info    LDAP集成消息
local                info    来自本地认证提供程序的消息
migrations           info    数据库迁移消息
oauth                info    服务器扩展的消息
oauth2               info    OAuth2消息
oidc                 info    OIDC提供程序的消息
root                 info    来自根凭证包的消息
server               info    来自服务主要的消息
```

在上面的输出中，最左边的列显示记录器名称，中间的列显示为该给定记录器配置的当前日志级别，最后一列显示记录器显示的消息类型的简要描述。

要更改日志级别，有多种方法可以完成，具体取决于`level`标志的不同组合。

### 更改单个记录器

可以通过提供记录器名称，后跟冒号（`:`），然后是所需的级别来更改单个记录器。例如：

```bash
tctl experimental debug log-level management/iamserver --level ldap:debug
配置日志级别：
    POST /logging?level=value	  -> 配置全局级别
    POST /logging?logger=value	  -> 配置'logger'的日志级别

当前的日志级别：

admin                info     管理服务器日志
auth                 info     认证消息服务器
config               info     来自配置系统的消息
credentials/basic    info     基本HTTP凭

证解析提供程序
credentials/jwt      info     JWT负载凭证解析提供程序
default              info     无作用域的日志消息。
dynadsn              info     来自动态数据库连接池的消息
envoy-filter         info     Envoy过滤器消息
exchange             info     令牌交换消息
grpc                 info     来自gRPC层的消息
health               info     健康检查服务的消息
iam-server           ldap     RunGroup处理程序的消息
iam/http             info     来自http服务器的消息
jwt                  info     LDAP提供程序的消息
keyvalue/tx          info     事务系统的消息
ldap                 info     LDAP集成消息
local                info     来自本地认证提供程序的消息
migrations           info     数据库迁移消息
oauth                info     服务器扩展的消息
oauth2               info     OAuth2消息
oidc                 info     OIDC提供程序的消息
root                 info     来自根凭证包的消息
server               info     来自服务主要的消息
```

如上所示，通过指定`--level`标志并提供`logger:level`的格式，你可以更改单个记录器的日志级别。在这个例子中，我们将`iamserver`的日志级别更改为`ldap:debug`。

### 更改多个记录器

要更改多个记录器的日志级别，可以使用逗号分隔它们，并将它们列在`--level`标志的值中。例如：

```bash
tctl experimental debug log-level management/iamserver --level ldap:debug,auth:info
配置日志级别：
    POST /logging?level=value	  -> 配置全局级别
    POST /logging?logger=value	  -> 配置'logger'的日志级别

当前的日志级别：

admin                info     管理服务器日志
auth                 info     认证消息服务器
config               info     来自配置系统的消息
credentials/basic    info     基本HTTP凭证解析提供程序
credentials/jwt      info     JWT负载凭证解析提供程序
default              info     无作用域的日志消息。
dynadsn              info     来自动态数据库连接池的消息
envoy-filter         info     Envoy过滤器消息
exchange             info     令牌交换消息
grpc                 info     来自gRPC层的消息
health               info     健康检查服务的消息
iam-server           ldap     RunGroup处理程序的消息
iam/http             info     来自http服务器的消息
jwt                  info     LDAP提供程序的消息
keyvalue/tx          info     事务系统的消息
ldap                 debug    LDAP集成消息
local                info     来自本地认证提供程序的消息
migrations           info     数据库迁移消息
oauth                info     服务器扩展的消息
oauth2               info     OAuth2消息
oidc                 info     OIDC提供程序的消息
root                 info     来自根凭证包的消息
server               info     来自服务主要的消息
```

在这个示例中，我们将`iamserver`的日志级别更改为`ldap:debug`，同时将`auth`的日志级别更改为`info`。

### 更改全局级别

要更改全局日志级别，你可以使用`POST /logging?level=value`命令。例如，要将全局日志级别设置为`debug`，请运行以下命令：

```bash
tctl experimental debug log-level management/iamserver --level debug
配置日志级别：
    POST /logging?level=value	  -> 配置全局级别
    POST /logging?logger=value	  -> 配置'logger'的日志级别

当前的日志级别：

admin                debug    管理服务器日志
auth                 debug    认证消息服务器
config               debug    来自配置系统的消息
credentials/basic    debug    基本HTTP凭证解析提供程序
credentials/jwt      debug    JWT负载凭证解析提供程序
default              debug    无作用域的日志消息。
dynadsn              debug    来自动态数据库连接池的消息
envoy-filter         debug    Envoy过滤器消息
exchange             debug    令牌交换消息
grpc                 debug    来自gRPC层的消息
health               debug    健康检查服务的消息
iam-server           debug    RunGroup处理程序的消息
iam/http             debug    来自http服务器的消息
jwt                  debug    LDAP提供程序的消息
keyvalue/tx          debug    事务系统的消息
ldap                 debug    LDAP集成消息
local                debug    来自本地认证提供程序的消息
migrations           debug    数据库迁移消息
oauth                debug    服务器扩展的消息
oauth2               debug    OAuth2消息
oidc                 debug    OIDC提供程序的消息
root                 debug    来自根凭证包的消息
server               debug    来自服务主要的消息
```

如上所示，运行此命令将更改所有记录器的日志级别为`debug`。这将导致 TSB 组件记录更多详细的日志信息。

以下是使用 Operator 更改记录器的内容：

### 使用 Operator 更改记录器

管理和控制平面的所有组件也可以通过使用MP/CP CRs 进行配置。例如，要修改`xcp-operator-edge`，你可以修改 CP CR 以使用以下配置：

```yaml
spec:
  components:
    xcp:
      kubeSpec:
        overlays:
        - apiVersion: apps/v1
        kind: Deployment
        name: xcp-operator-edge
        patches:
        - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
          value: --log_output_level
        - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
          value: all:error
```

请注意，有些组件是由其他 Operator 部署的，比如控制平面中的`edge`。要修改这些组件，你需要对 Operator 进行叠加，如下所示：

```yaml
spec:
  components:
    xcp:
      kubeSpec:
        overlays:
        - apiVersion: apps/v1
          kind: Deployment
          name: xcp-operator-edge
          patches:
          - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
            value: --log_output_level
          - path: spec.template.spec.containers.[name:xcp-operator].args[-1]
            value: all:error
        # 添加 edge 的叠加
        - apiVersion: install.xcp.tetrate.io/v1alpha1
          kind: EdgeXcp
          name: edge-xcp
          patches:
          - path: spec.components.edgeServer.kubeSpec.overlays
            value:
            - apiVersion: v1
              kind: Deployment
              name: edge
              patches:
              - path: spec.template.spec.containers.[name:edge].args[all:info]
                value: all:error
```

如果要修改`istiod`或 istioOperator 的所有网关的日志记录器，你需要从部署`istiod`的组件`istio-operator`进行叠加：

```yaml
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.values.global.proxy.logLevel
            value: warn
          - path: spec.values.global.logging.level
            value: default:warn
```

上述示例适用于管理或控制平面 Operator 部署的所有组件，但如果要修改 Operator 本身的记录器日志级别，你需要手动编辑 Operator 部署。例如，让我们更改控制平面 Operator 部署的记录器的日志级别：

```bash
kubectl edit deployment tsb-operator-control-plane -n istio-system
```

```yaml
spec:
  template:
    spec:
      containers:
      - args:
        - control-plane
        - --deployment-name
        - tsb-operator-control-plane
        # 在以下更改之后添加
        - --log-output-level
        - default:info,tsboperator/kubernetes:error
```

### 使用安装 API 配置记录器

大多数组件都提供了选择特定组件的日志级别的旋钮。可以使用 Install API CRs（如 MP 或 CP）来执行此操作。以下是示例：
例如，在 CP CR 中：

```bash
kubectl edit deployment tsb-operator-control-plane -n istio-system
```

```yaml
spec:
  components:
    xcp:
      logLevels:
        all: error
    oap:
      logLevel: debug
    istio:
      logLevels:
        all: trace
```

此外，还可以为所有组件设置默认日志级别。由于不同组件可能具有不同的日志级别，因此默认日志级别仅对使用特定日志级别的组件进行呈现。
例如，在 CP CR 中：

```yaml
spec:
  defaultLogLevel: info
```

类似地，也可以在 MP 中执行此操作。

查看 MP 和 CP CR 中支持的不同组件和日志级别的组件的详细信息：

- [控制平面 Install API 参考文档](../../refs/install/controlplane/v1alpha1/spec)。
- [管理平面 Install API 参考文档](../../refs/install/managementplane/v1alpha1/spec)。

## 配置入口网关的日志级别

要更改网关的日志级别，可以使用上面描述的

相同过程。请注意，`list-components`命令的输出还包括当前集群中部署的网关，位于`data`平面下。

```bash
$ tctl experimental debug list-components  | egrep ^data
data          tsb-operator              tsb-operator-data-plane                  
data          operator                  istio-operator                           
data          bookinfo-gateway          bookinfo/bookinfo-gateway                
data          helloworld-tls-gateway    helloworld-tls/helloworld-tls-gateway    
data          helloworld-gateway        helloworld/helloworld-gateway            
data          httpbin-gateway           httpbin/httpbin-gateway                  
data          tier1                     tier1/tier1
```

更改网关的日志级别的过程与其他组件相同。例如，要验证`bookinfo-gateway`的日志级别，请运行以下命令：

```bash
$ tctl experimental debug log-level data/bookinfo-gateway
active loggers:
  admin: trace
  aws: trace
  assert: trace
  backtrace: trace
  cache_filter: trace
  client: trace
  config: trace
  connection: trace
  conn_handler: trace
  decompression: trace
  dubbo: trace
  envoy_bug: trace
  ext_authz: trace
  rocketmq: trace
  file: trace
  filter: trace
  forward_proxy: trace
  grpc: trace
  hc: trace
  health_checker: trace
  http: trace
  http2: trace
  hystrix: trace
  init: trace
  io: trace
  jwt: trace
  kafka: trace
  lua: trace
  main: trace
  matcher: trace
  misc: trace
  mongo: trace
  quic: trace
  quic_stream: trace
  pool: trace
  rbac: trace
  redis: trace
  router: trace
  runtime: trace
  stats: trace
  secret: trace
  tap: trace
  testing: trace
  thrift: trace
  tracing: trace
  upstream: trace
  udp: trace
  wasm: trace
```

然后，可以使用相同的过程调整日志级别，例如，将所有记录器设置为`info`级别，可以使用以下命令：

```bash
$ tctl experimental debug log-level data/bookinfo-gateway --level info
active loggers:
  admin: info
  aws: info
  assert: info
  backtrace: info
  cache_filter: info
  client: info
  config: info
  connection: info
  conn_handler: info
  decompression: info
  dubbo: info
  envoy_bug: info
  ext_authz: info
  rocketmq: info
  file: info
  filter: info
  forward_proxy: info
  grpc: info
  hc: info
  health_checker: info
  http: info
  http2: info
  hystrix: info
  init: info
  io: info
  jwt: info
  kafka: info
  lua: info
  main: info
  matcher: info
  misc: info
  mongo: info
  quic: info
  quic_stream: info
  pool: info
  rbac: info
  redis: info
  router: info
  runtime: info
  stats: info
  secret: info
  tap: info
  testing: info
  thrift: info
  tracing: info
  upstream: info
  udp: info
  wasm: info
```

这将调整网关部署的所有副本 Pod 的日志级别。

## 使用`istioctl`配置数据平面的日志级别

已部署在服务网格中的服务可以在运行时动态控制其日志记录。可以使用多种方式更改这些级别，但最简单的方式是使用[`istioctl proxy-config log`](https://istio.io/latest/docs/reference/commands/istioctl/#istioctl-proxy-config-log)命令。

```bash
istioctl proxy-config log <pod-name[.namespace]> --level <arguments>
```

`arguments`可以采用以下两种形式之一：`level=<name>`或`<logger>=<name>`。

使用`level=<name>`形式时，所有适用的组件将被设置为`name`指定的日志级别。使用`<logger>=<name>`形式时，将更改由`logger`指定的特定记录器的日志级别。最后，可以在单个命令中列出多个记录器，例如`<logger1>=<name1>,<logger2>=<name2>,<logger3>=<name3>`。

允许以下名称：`none`、`default`、`debug`、`info`、`warn`或`error`。

有关不同日志级别和可用的记录器的详细信息，请参阅[`istioctl proxy-config log`](https://istio.io/latest/docs/reference/commands/istioctl/#istioctl-proxy-config-log)的文档。

{{<callout note "你还可以直接使用 kubectl 查看日志级别！">}}

已部署在服务网格中的服务将包含`pilot-agent`命令在 sidecar 容器中。它的主要责任是引导 Envoy 代理，但它也可以用于在运行时配置日志级别，以及其他任务。

`pilot-agent`命令可以通过`kubectl`在 sidecar 上执行以更新日志级别，如下所示：

```bash
kubectl exec <pod-name> -c istio-proxy -- \
  pilot-agent request POST 'logging?<arguments>'
```

`pod-name`是目标 Kubernetes Pod。请注意，我们使用了`-c istio-proxy`选项来明确指定我们正在 sidecar 中执行`pilot-agent`命令，该 sidecar 位于`pod-name`中
{{</callout>}}

## 为应用程序 sidecar 配置日志级别

### 验证已部署的应用程序 Pod

验证`istio-proxy` sidecar 是否正确部署：

```bash
kubectl get pods -n helloworld -o jsonpath="{.items[*].spec.containers[*].name}" | \
  tr -s '[[:space:]]' '\n' | \
  sort | \
  uniq -c | \
  grep istio-proxy
```

这应该输出类似以下的文本：

```
  2 istio-proxy
```

### 调整日志级别

在这个示例中，我们假设以下应用程序已经部署并加入了 TSB：

```
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-2h8dq   2/2     Running   0          5h49m
helloworld-v2-54df5f84b-v2wv6    2/2     Running   0          5h49m
```

要调整日志级别，可以运行以下命令：

```bash
istioctl proxy-config log helloworld-v1-776f57d5f6-2h8d --level debug
```

{{<callout warning 注意>}}
建议不要在生产工作负载或高流量系统的工作负载上启用`debug`日志级别。它们可能会打印大量信息，可能会压倒你的应用程序，或者至少会让你花费大量的日志摄取费用！
{{</callout>}}

一旦上述命令生效，你将能够使用`kubectl`查看 sidecar 的调试日志：

```bash
kubectl logs -f helloworld-v1-776f57d5f6-2h8dq -c istio-proxy
```

如果你希望将相同的更改应用于应用程序的其他 sidecar，请必须对你感兴趣的每个 Pod 重复此过程。

{{<callout note "使用 kubectl 更改日志级别">}}
应用程序 Pod 中的`istio-proxy` sidecar 包含`pilot-agent`命令。

可以使用`kubectl`在 sidecar 上执行以下命令配置日志级别：
```bash
kubectl -n helloworld exec helloworld-v1-776f57d5f6-2h8dq -c istio-proxy -- \
  pilot-agent request POST 'logging?level=debug'
```
{{</callout>}}

### 重置日志级别

在查看日志后，一定要确保再次调整日志级别。这也必须针对已调整日志级别的每个 sidecar 进行。

`istioctl`有一个快捷方式来执行此操作：

```bash
istioctl proxy-config log helloworld-v1-776f57d5f6-2h8dq --reset
```

{{<callout note "对于`kubectl`，没有用于重置日志级别的快捷方式">}}
不幸的是，`kubectl`没有用于通过`kubectl`重置日志级别的快捷方式。你需要使用`kubectl exec`命令执行一个命令，该命令将还原你使用一系列日志范围和级别更改的所有日志，例如：
```bash
kubectl -n helloworld exec helloworld-v1-776f57d5f6-2h8dq -c istio-proxy -- \
  pilot-agent request POST 'logging?h2=debug,http=info,grpc=error'
```
{{</callout>}}

## 使用配置更改日志级别

`tctl`命令行实用程序包括另一种配置日志级别的方式，即使用包含用于配置流量流的实际配置对象的文件。例如，对于给定的`IngressGateway`：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  http:
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-certs
    routing:
      rules:
      - route:
          host: ns1/productpage.ns1.svc.cluster.local
```

`tctl`命令将调整与`workloadSelector`匹配的 Pod 的日志级别，以及服务目标为`productpage.ns1.svc.cluster.local`的 Pod 的日志级别。这也适用于直接模式，检查等效对象（`Gateway`、`VirtualService`等）。这对于排查入口或东/西流量的数据路径非常有用，你可以利用`tctl get all`命令的输出来配置在请求给定主机名时处于数据路径中的适当 Pod。

```bash
tctl get all --fqdn bookinfo.com > /tmp/bookinfo-config.yaml
tctl experimental debug log-levels -f /tmp/bookinfo-config.yaml --level=trace
```

上述命令会查询 TSB 并获取所有引用主机名 `bookinfo.com` 的配置对象，将它们保存到文件 `/tmp/bookinfo-config.yaml` 中。第二个命令会为 `bookinfo.com` 主机名的数据路径中的所有 Pod 将日志级别配置为 `trace`。一旦故障排除完成，你可以将日志级别恢复为更合理的值。

```bash
tctl experimental debug log-levels -f /tmp/bookinfo-config.yaml --level=info
```

{{<callout note 多集群>}}
调整日志级别的命令使用当前配置的 `kubectl` 配置文件和上下文，而你的配置可能扩展到多个集群。例如，你可以在同一个文件中包含 Tier1 和 Tier2 的配置。`tctl`将显示匹配的 Pod，并在继续之前要求确认。如果需要使用多个集群，你需要使用 `kubectl` 针对每个集群运行一次命令。
{{</callout>}}

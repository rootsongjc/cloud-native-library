---
title: 配置（多端口、多协议）服务的 ServiceRoute
description: 配置多端口服务通过单个`ServiceRoute`配置的路由的指南。
weight: 5
---

本操作指南将向你展示如何配置路由到通过单个`ServiceRoute`配置公开多个端口的服务。

## 场景

考虑一个名为`tcp-echo`的后端服务，它通过 TCP 公开了两个端口，`9000`和`9001`。该服务有两个版本`v1`和`v2`，需要在这两个版本之间实现对这两个端口的流量分配。为了实现这一目标，需要配置具有端口级设置的`ServiceRoute`。

## 部署`tcp-echo`服务

从 Istio 的示例目录中安装`tcp-echo`应用程序到`echo`命名空间中，安装[这些清单](https://github.com/istio/istio/blob/master/samples/tcp-echo/tcp-echo-services.yaml)。

## TSB 配置

### 部署工作区和流量组

应用以下配置来创建一个工作区和一个流量组。

{{<callout note 提示>}}
这些示例假设你已经创建了一个名为 `tetrateio` 的组织和一个名为 `tetrate` 的租户。
{{</callout>}}

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
 name: tcp-multiport-ws
 organization: tetrateio
 tenant: tetrate
spec:
 namespaceSelector:
   names:
     - "*/echo"
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
 name: tcp-multiport-tg
 organization: tetrateio
 tenant: tetrate
 workspace: tcp-multiport-ws
spec:
 configMode: BRIDGED
 namespaceSelector:
   names:
   - "*/echo"
```

### 部署`ServiceRoute`

应用以下配置来创建配置两个端口的`ServiceRoute`。

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: tcp-multiport-service-route
  organization: tetrateio
  tenant: tetrate
  workspace: tcp-multiport-ws
  group: tcp-multiport-tg
spec:
  service: "echo/tcp-echo.svc.cluster.local"
  portLevelSettings:
    - port: 9000
      trafficType: TCP
    - port: 9001
      trafficType: TCP
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 80
    - name: v2
      labels:
        version: v2
      weight: 20
```

## 测试

为了验证路由已成功设置，多次尝试向`echo` pod 发送 curl 请求。由于`v1:v2`之间的权重比设置为`80:20`，大多数情况下请求将转发到`v1` pod。

对于测试 TCP 流量，请使用`nc`。

```bash
kubectl -n echo exec -it <pod-name> -c <container-name> -- curl -sv tcp-echo.svc.cluster.local:9000
kubectl -n echo exec -it <pod-name> -c <container-name> -- sh -c "echo hello | nc -v tcp-echo.svc.cluster.local:9001"
```
---
title: 使用 SkyWalking 进行 HPA
description: 在 TSB 管理的集群中使用 SkyWalking 进行水平 Pod 自动缩放（HPA）
weight: 8
---

[Apache SkyWalking Cloud on Kubernetes (SWCK)](https://github.com/apache/skywalking-swck) 提供了一个外部度量适配器，从中 [Kubernetes 水平 Pod 自动缩放（HPA）](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) 控制器可以检索度量数据。用户可以将 SWCK 适配器部署到 TSB 控制平面中，以从 [Observability Analysis Platform (OAP)](https://skywalking.apache.org/docs/main/latest/en/concepts-and-designs/backend-overview/) 服务中获取目标度量数据。

在开始之前，请确保你已经：
- 熟悉 [TSB 概念](../../concepts/)
- 安装了 [TSB 演示](../../setup/self-managed/demo-installation) 环境
- 部署了 [Istio Bookinfo](../../quickstart/deploy-sample-app) 示例应用程序

## 验证 SWCK 度量适配器

SWCK 适配器负责管理 `OAP` 组件等。

该适配器应在安装 TSB 演示配置文件时已安装。要验证适配器是否成功部署，请检查相应的 Pod 是否已正确启动。

```bash
kubectl get po -n istio-system

... <snip> ...
istio-system-custom-metrics-apiserver-7cdbb5bdbb-zmwh7   1/1     Running   0    5m54s
```

如果由于某种原因以下资源未正确更新/生成，请尝试手动删除它们。删除它们应触发创建一个新的 Pod，具有最新的配置：

* `apiservice/v1beta1.external.metrics.k8s.io`
* `rolebinding/istio-system-custom-metrics-auth-reader`（在 `kube-system` 命名空间中）

## HPA 配置

要启用使用 SWCK 适配器的 `HorizontalPodAutoscaler`，你需要使用 `External` 度量类型来设置配置。

`External` 度量类型允许你根据 `OAP` 集群中可用的任何度量数据自动调整你的集群。要使用此功能，请提供一个带有名称和选择器的度量块，并使用 External 度量类型。

```yaml
kind: HorizontalPodAutoscaler
metadata:
  name: productpage-hpa-external-metrics
spec:
- type: External
  external:
    metric:
      name: <metric_name>
      metricSelector:
        matchLabels:
          <label_key>: <label_value>
          ...
    target:
      ....
```

`metric_name` 应为 [Observability Analysis Language (OAL)](https://skywalking.apache.org/docs/main/latest/en/concepts-and-designs/oal/) 或其他子系统生成的度量名称。

`label_key` 是 SkyWalking 度量的实体名称。如果 `label_value` 包含除 "`.`"、"`-`" 和 "`_`" 之外的特殊字符，则应该使用 "byte" 标签将其编码为十六进制字节。`service.str.<number>` 将表示标签值的文字，而`service.byte.<number>` 可以用于表示十六进制字节的特殊字符。

例如，如果服务名称为 `v1|productpage|bookinfo|demo`，则 `matchLabels` 应如下所示：

```yaml
matchLabels:
  "service.str.0":  "v1"
  "service.byte.1": "7c" # "|" 的十六进制字节
  "service.str.2":  "productpage"
  "service.byte.3": "7c"
  "service.str.4":  "bookinfo"
  "service.byte.5": "7c"
  "service.str.6":  "demo"
```

请注意，字节标签只接受单个字符。这意味着输入如 `||` 的情况应该被转换为两个条目，包括 `"service.byte.0":"7c"` 和 `"service.byte.1":"7c"`，而不是 `service.byte.0:"7c7c"`。

`label_keys` 可以包含用于服务名称、服务实例、端点名称和查询标签的实体名称。例如，要编码服务名称，你将使用 `"service.str.<number>"` 或 `"service.byte.<number>"`，要编码端点，你将使用 `"endpoint.str.<number>"` 和 `"endpoint.byte.<number>"`，依此类推。

## 一个综合示例

假设你想要自动调整部署，以确保始终有足够的副本接受每分钟大约 80 个请求。

假设你的 "demo" 集群中的 "productpage-v1" 部署基于 OAP 中的 "`service_cpm`" 指标，并且服务名称为 "v1|productpage|demo|-"，则你的 HPA 清单应如下所示：

```yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: productpage-hpa-external-metrics
spec:
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: External
    external:
      metric:
        name: tsb.tetrate.io|service_cpm
        selector:
          matchLabels:
            "service.str.0":  "v1"
            "service.byte.1": "7c"
            "service.str.2":  "productpage"
            "service.byte.3": "7c"
            "service.str.4":  "bookinfo"
            "service.byte.5": "7c"
            "service.str.6":  "demo"
            "service.byte.7": "7c"
            "service.byte.8": "2d"
      target:
        type: AverageValue
        value: 80
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: productpage-v1
```

一旦使用 `kubectl apply -f` 应用了上述清单，你应该在你的 bookinfo 命名空间中看到创建的 HPA：

```bash
kubectl get hpa -n bookinfo
NAME                               REFERENCE                         TARGETS   MINPODS   MAXPODS   REPLICAS   
...<snip>...
productpage-hpa-external-metrics   Deployment/productpage-v1         0/80      1         5         1        
```

要测试你的应用程序，请使用类似 [Hey](https://github.com/rakyll/hey) 的工具生成一些负载。
最终，你应该看到 HPA 创建了更多的副本来处理负载：

```bash
kubectl get hpa -n bookinfo
NAME                               REFERENCE                         TARGETS   MINPODS   MAXPODS   REPLICAS   
...<snip>...
productpage-hpa-external-metrics   Deployment/productpage-v1         2252/80   1         10        4  
```

请阅读 SWCK 度量适配器文档以获取更多详细信息。

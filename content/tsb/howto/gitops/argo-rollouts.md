---
title: "使用 Argo Rollout 和 SkyWalking 进行金丝雀分析和渐进式交付"
description: "如何使用 TSB GitOps 支持进行金丝雀部署分析和渐进式交付工作流，使用 Argo CD、Argo Rollout 和 SkyWalking 作为金丝雀部署分析和渐进式交付自动化的指标提供者。"
weight: 3
---

本文档描述了如何配置 Argo CD 并将 Argo Rollout 与 TSB GitOps 支持集成，以及如何使用 SkyWalking 作为金丝雀部署分析和渐进式交付自动化的指标提供者。

在开始之前，请确保以下事项：
- [Argo CD](https://argo-cd.readthedocs.io/en/stable/getting-started/) 已安装在你的集群中，并且已配置 Argo CD CLI 以连接到你的 Argo CD 服务器
- [Argo Rollout ](https://argoproj.github.io/argo-rollouts/installation/) 已安装在你的集群中
- TSB 已启动并运行，并且已为目标集群启用了 GitOps [配置](../../../operations/features/configure-gitops)

## 从 Git 仓库创建应用程序

使用以下命令创建一个示例应用程序。一个包含 Istio 的示例仓库，其中包含 Istio 的 [bookinfo](https://istio.io/latest/docs/examples/bookinfo/) 应用程序和 TSB 配置，可以在 [https://github.com/tetrateio/tsb-gitops-demo](https://github.com/tetrateio/tsb-gitops-demo) 上找到。
你可以使用 Argo CD CLI 或其 Web UI 直接从 Git 导入应用程序配置。

```bash
argocd app create bookinfo-app --repo https://github.com/tetrateio/tsb-gitops-demo.git --path application --dest-server https://kubernetes.default.svc --dest-namespace bookinfo --sync-policy automated --self-heal
```

检查应用程序的状态

```bash
argocd app get bookinfo-app
```

```bash
Name:               bookinfo-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          bookinfo
URL:                https://localhost:8080/applications/bookinfo-app
Repo:               https://github.com/tetrateio/tsb-gitops-demo.git
Target:             
Path:               argo/app
SyncWindow:         Sync Allowed
Sync Policy:        Automated
Sync Status:        Synced to (1ba8e2d)
Health Status:      Healthy

GROUP  KIND            NAMESPACE  NAME                  STATUS     HEALTH   HOOK  MESSAGE
       Namespace       bookinfo   bookinfo              Running    Synced         namespace/bookinfo created
       ServiceAccount  bookinfo   bookinfo-details      Synced                    serviceaccount/bookinfo-details created
       ServiceAccount  bookinfo   bookinfo-productpage  Synced                    serviceaccount/bookinfo-productpage created
       ServiceAccount  bookinfo   bookinfo-ratings      Synced                    serviceaccount/bookinfo-ratings created
       ServiceAccount  bookinfo   bookinfo-reviews      Synced                    serviceaccount/bookinfo-reviews created
       Service         bookinfo   productpage           Synced     Healthy        service/productpage created
       Service         bookinfo   details               Synced     Healthy        service/details created
       Service         bookinfo   ratings               Synced     Healthy        service/ratings created
       Service         bookinfo   reviews               Synced     Healthy        service/reviews created
apps   Deployment      bookinfo   ratings-v1            Synced     Healthy        deployment.apps/ratings-v1 created
apps   Deployment      bookinfo   productpage-v1        Synced     Healthy        deployment.apps/productpage-v1 created
apps   Deployment      bookinfo   reviews               OutOfSync  Healthy        deployment.apps/reviews created
apps   Deployment      bookinfo   details-v1            Synced     Healthy        deployment.apps/details-v1 created
       Namespace                  bookinfo              Synced
```

## 应用程序设置

如果你已经为部署和服务资源创建了 Kubernetes 清单，你可以选择保留相同的对象以及 Argo `Rollout` 对象，以便实现金丝雀部署。
你可以对 `Rollout` 对象和 Istio VirtualService/DestinationRule 的 TSB 网格配置进行必要的更改，以实现所需的结果。

## TSB 配置设置

由于 Argo Rollout 要求你根据其 Istio 的金丝雀部署策略约定对 Istio 的 `VirtualService` 和 `DestinatrionRule` 对象进行一些修改，你可以使用 TSB 的 `DIRECT` 模式配置来实现所需的结果。

* 根据 Argo Rollout 的约定，需要在 TSB 直接模式资源（如 `VirtualService` 和 `DestinationRule`）中配置 2 个子集，分别命名为 `stable` 和 `canary`，并添加必要的标签，以标识 `canary` 和 `stable` 的 Pod。
* 请确保版本标签（例如：`version: canary/stable`）已根据 Istio 的约定进行配置，以便 TSB 可识别子集并在服务仪表板中绘制指标。
* 在使用 TSB 直接模式资源与 GitOps 时，需要为资源添加一个额外的标签 `istio.io/rev: "tsb"`。有关更多详细信息，请参阅[此处](./gitops.md)。

通过从 [tsb-gitops-demo/argo/tsb/conf.yaml](https://github.com/tetrateio/tsb-gitops-demo/blob/main/argo/tsb/conf.yaml) 导入 TSB 配置来创建一个名为 `bookinfo-tsb-conf` 的应用。你也可以选择将其保存在同一存储库中。

```bash
argocd app create bookinfo-tsb-conf --repo https://github.com/tetrateio/tsb-gitops-demo.git --path argo/tsb --dest-server https://kubernetes.default.svc --dest-namespace bookinfo --sync-policy automated --self-heal
```

检查 TSB 资源的状态

```bash
argocd app get bookinfo-tsb-conf
```

结果：

```
Name:               bookinfo-tsb-conf
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          bookinfo
URL:                https://localhost:8080/applications/bookinfo-tsb-conf
Repo:               https://github.com/tetrateio/tsb-gitops-demo.git
Target:             
Path:               argo/tsb
SyncWindow:         Sync Allowed
Sync Policy:        Automated
Sync Status:        Synced to (1ba8e2d)
Health Status:      Healthy

GROUP                    KIND             NAMESPACE     NAME                               STATUS     HEALTH  HOOK  MESSAGE
networking.istio.io      VirtualService   bookinfo      bookinfo                           Synced                   virtualservice.networking.istio.io/bookinfo created
tsb.tetrate.io           Tenant           bookinfo      bookinfo                           Synced                   tenant.tsb.tetrate.io/bookinfo unchanged
networking.istio.io      Gateway          bookinfo      bookinfo-gateway                   Synced                   gateway.networking.istio.io/bookinfo-gateway unchanged
traffic.tsb.tetrate.io   Group            bookinfo      bookinfo-traffic                   Synced                   group.traffic.tsb.tetrate.io/bookinfo-traffic unchanged
security.tsb.tetrate.io  Group            bookinfo      bookinfo-security                  Synced                   group.security.tsb.tetrate.io/bookinfo-security unchanged
gateway.tsb.tetrate.io   Group            bookinfo      bookinfo-gateway                   Synced                   group.gateway.tsb.tetrate.io/bookinfo-gateway unchanged
tsb.tetrate.io           Workspace        bookinfo      bookinfo-ws                        Synced                   workspace.tsb.tetrate.io/bookinfo-ws unchanged
networking.istio.io      VirtualService   bookinfo      details                            Synced                   virtualservice.networking.istio.io/details unchanged
networking.istio.io      DestinationRule  bookinfo      productpage                        Synced                   destinationrule.networking.istio.io/productpage unchanged
networking.istio.io      DestinationRule  bookinfo      details                            Synced                   destinationrule.networking.istio.io/details unchanged
networking.istio.io      VirtualService   bookinfo      ratings                            Synced                   virtualservice.networking.istio.io/ratings unchanged
networking.istio.io      DestinationRule  bookinfo      reviews                            Synced                   destinationrule.networking.istio.io/reviews unchanged
networking.istio.io      DestinationRule  bookinfo      ratings                            Synced                   destinationrule.networking.istio.io/ratings unchanged
networking.istio.io      VirtualService   bookinfo      reviews                            Synced                   virtualservice.networking.istio.io/reviews unchanged
install.tetrate.io       IngressGateway   bookinfo      tsb-gateway-bookinfo               Synced                   ingressgateway.install.tetrate.io/tsb-gateway-bookinfo unchanged
```

## 验证应用程序

运行以下命令以导出 `tsb-gateway-bookinfo` 的负载均衡 IP 地址。

```bash
export GATEWAY_IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

确认你可以访问 bookinfo 应用程序。如你在响应中所见，我们当前部署的 `review v1` 服务不会调用 `ratings` 服务。

```bash
curl -v "http://bookinfo.tetrate.com/api/v1/products/1/reviews" \
    --resolve "bookinfo.tetrate.com:80:$GATEWAY_IP"
```

```
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-type: application/json
< content-length: 361
< server: istio-envoy
< date: Mon, 22 Aug 2022 06:36:52 GMT
< x-envoy-upstream-service-time: 782
<
* Connection #0 to host bookinfo.tetrate.com left intact
{"id": "1", "podname": "reviews-rollout-56ff4b868c-74d8t", "clustername": "null", "reviews": [{"reviewer": "Reviewer1", "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!"}, {"reviewer": "Reviewer2", "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare."}]}
```

## 设置 Argo Rollout

Argo Rollout 提供了多种选项，可将你现有的 Kubernetes 部署对象迁移到 Argo 的 `Rollout` 对象中。你可以将现有的 Kubernetes 部署对象转换为 `Rollout`，或者可以使用 `workloadRef` 从 `Rollout` 对象中引用你现有的 Kubernetes 部署。在本示例中，我们将使用后一种方法。

在此示例中，我们将进行 `reviews` 服务的金丝雀部署，以演示 `Rollout` 对象的配置以及如何将流量转移至 `reviews` 服务的主要部署和金丝雀部署。

* 创建一个 `Rollout` 资源，并使用 `workloadRef` 引用你现有的部署。
* 确保 `matchLabels` 选择器已根据你的 Kubernetes 应用程序部署清单进行配置。
* 将策略配置为 `canary`，并配置子集级别的流量分配。
* 配置 `canaryMetadata` 和 `stableMetadata`，以在 `canary` 和 `stable` Pod 上注入标签和注释。
* 请确保 `canaryMetadata` 和 `stableMetadata` 的标签与 TSB 直接模式配置[此处](https://github.com/tetrateio/tsb-gitops-demo/blob/main/argo/tsb/conf.yaml#L157-L165)一致。
* 根据 TSB 直接模式配置，在 `trafficRouting` 下配置 Istio 的 `virtualService` 和 `destinationRule`。

创建 `Rollout` 对象后，它将与 Kubernetes 部署 Pod 并排运行所需数量的 Pod。
在所有 `Rollout` Pod 启动并运行后，你可以通过更改副本数将现有的 Kubernetes 部署缩减到 `0`，从而将流量切换到由 `Rollout` 对象管理的 Pod。 `Rollout` 对象不会修改你现有的 Kubernetes 部署，在 `VirtualService` 中更新子集后，流量将被转移到由 `Rollout` 对象管理的 Pod 上。

<details>
<summary>reviews-rollout.yaml</summary>

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: reviews-rollout
spec:
  replicas: 5
  selector:
    matchLabels:
      app: reviews
  workloadRef:
    apiVersion: apps/v1
    kind: Deployment
    name: reviews
  strategy:
    canary:
      analysis:
        templates:
        - templateName: apdex
        startingStep: 2
        args:
        - name: service-name
          value: canary|reviews|bookinfo|cp-cluster-1|-
      canaryMetadata:
        annotations:
          version: canary
        labels:
          version: canary
          service.istio.io/canonical-revision: canary
      stableMetadata:
        annotations:
          version: stable
        labels:
          version: stable
          service.istio.io/canonical-revision: stable
      trafficRouting:
        istio:
          virtualService: 
            name: reviews
          destinationRule:
            name: reviews    
            canarySubsetName: canary  
            stableSubsetName: stable
      steps:
      - setWeight: 10
      - pause: {duration: 10m}
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}
```
</details>

## 使用 SkyWalking 配置金丝雀分析模板

[SkyWalking](https://skywalking.apache.org/)，一个捆绑在 TSB 中的可观察性组件，可以作为度量提供程序来支持金丝雀部署分析，从而实现自动升级或回滚操作。有关更多详细信息，请参阅[Argo Rollout 中的分析与渐进式交付](https://argoproj.github.io/argo-rollouts/features/analysis/)以及如何使用[SkyWalking](https://argoproj.github.io/argo-rollouts/analysis/skywalking/)作为度量提供程序的内容。

* 使用 `skywalking` 作为度量提供程序创建金丝雀 `AnalysisTemplate`，以驱动基于部署分析的自动升级/回滚操作。
* 可以通过连接到 `OAP` 服务 GraphQL 端点，即安装在 TSB 控制平面集群上的 `http://oap.istio-system:12800` 来获取 SkyWalking 度量。
* 成功条件是使用 Apdex 分数派生的。有关更多详细信息，请阅读[用于衡量服务网格健康的 Apdex 分数](https://tetrate.io/blog/the-apdex-score-for-measuring-service-mesh-health/)。
* 金丝雀部署的子集

名称需要配置为 `analysis` 模板中的参数 `service-name`。
* SkyWalking 中 TSB 服务名称的格式为 `subset|service name|namespace name|cluster name|-`。由于我们使用 `reviews` 服务，请在 Rollout 资源的 `service-name` 值中使用 `canary|reviews|bookinfo|cp-cluster-1|-`。

在 `Rollout` 对象中的金丝雀 `analysis` 中配置相同的 `AnalysisTemplate` 详细信息。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: apdex
spec:
  args:
  - name: service-name
  metrics:
  - name: apdex
    interval: 5m
    successCondition: "all(result.service_apdex.values.values, {asFloat(.value) >= 9900})"
    failureLimit: 3
    provider:
      skywalking:
        interval: 3m
        address: http://oap.istio-system:12800
        query: |
          query queryData($duration: Duration!) {
            service_apdex: readMetricsValues(
              condition: { name: "service_apdex", entity: { scope: Service, serviceName: "{{ args.service-name }}", normal: true } },
              duration: $duration) {
                label values { values { value } }
              }
          }
```

## 创建 Rollout

运行以下命令以创建一个 rollout 应用程序。

```bash
argocd app create reviews-rollout --repo https://github.com/tetrateio/tsb-gitops-demo.git --path argo/rollout --dest-server https://kubernetes.default.svc --dest-namespace bookinfo --sync-policy automated --self-heal
```

检查状态

```bash
argocd app get reviews-rollout
```

结果：

```
Name:               reviews-rollout
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          bookinfo
URL:                https://localhost:8080/applications/reviews-rollout
Repo:               https://github.com/tetrateio/tsb-gitops-demo.git
Target:             
Path:               argo/rollout
SyncWindow:         Sync Allowed
Sync Policy:        Automated
Sync Status:        Synced to (1ba8e2d)
Health Status:      Healthy

GROUP        KIND              NAMESPACE  NAME             STATUS  HEALTH   HOOK  MESSAGE
argoproj.io  AnalysisTemplate  bookinfo   apdex            Synced                 analysistemplate.argoproj.io/apdex created
argoproj.io  Rollout           bookinfo   reviews-rollout  Synced  Healthy        rollout.argoproj.io/reviews-rollout created
```

## 触发金丝雀部署

将 `reviews` 服务的部署图像更新为 `v2` 版本，这将立即触发 `reviews v2` 的金丝雀部署，并将流量百分比更改为 `90/10`。

```bash
kubectl argo rollouts set image reviews-rollout reviews=docker.io/istio/examples-bookinfo-reviews-v2:1.16.4 -n bookinfo
```

## 监控金丝雀部署

运行以下命令以监控你的金丝雀部署。

```bash
kubectl argo rollouts get rollout reviews-rollout --watch -n bookinfo
```

结果

```
Name:            reviews-rollout
Namespace:       bookinfo
Status:          ॥ Paused
Message:         CanaryPauseStep
Strategy:        Canary
  Step:          1/10
  SetWeight:     10
  ActualWeight:  10
Images:          docker.io/istio/examples-bookinfo-reviews-v1:1.16.4 (stable)
                 docker.io/istio/examples-bookinfo-reviews-v2:1.16.4 (canary)
Replicas:
  Desired:       5
  Current:       6
  Updated:       1
  Ready:         6
  Available:     6

NAME                                         KIND        STATUS     AGE    INFO
⟳ reviews-rollout                            Rollout     ॥ Paused   6m13s
├──# revision:2
│  └──⧉ reviews-rollout-867b9c9bcb           ReplicaSet  ✔ Healthy  21s    canary
│     └──□ reviews-rollout-867b9c9bcb-86mbt  Pod         ✔ Running  19s    ready:2/2
└──# revision:1
   └──⧉ reviews-rollout-5d9dc876c9           ReplicaSet  ✔ Healthy  6m13s  stable
      ├──□ reviews-rollout-5d9dc876c9-27mth  Pod         ✔ Running  6m12s  ready:2/2
      ├──□ reviews-rollout-5d9dc876c9-8qqpx  Pod         ✔ Running  6m11s  ready:2/2
      ├──□ reviews-rollout-5d9dc876c9-9bqbv  Pod         ✔ Running  6m11s  ready:2/2
      ├──□ reviews-rollout-5d9dc876c9-cgxgd  Pod         ✔ Running  6m11s  ready:2/2
      └──□ reviews-rollout-5d9dc876c9-d447w  Pod         ✔ Running  6m11s  ready:2/2
```

## 生成流量

运行以下命令以向 bookinfo 应用程序发送一些请求。

```bash
while true; do curl -m 5 -v "http://bookinfo.tetrate.com/api/v1/products/1/reviews" --resolve "bookinfo.tetrate.com:80:$GATEWAY_IP";  sleep 2 ; done ;
```

正如你所见，部分响应将包含来自 `ratings` 服务的响应，因为 `reviews-v2` 调用了 `ratings` 服务。

```
> GET /api/v1/products/1/reviews HTTP/1.1
> Host: bookinfo.tetrate.com
> User-Agent: curl/7.79.1
> Accept: */*
> Content-Length: 0
> Content-Type: application/x-www-form-urlencoded
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-type: application/json
< content-length: 437
< server: istio-envoy
< date: Mon, 22 Aug 2022 06:53:14 GMT
< x-envoy-upstream-service-time: 45
<
* Connection #0 to host bookinfo.tetrate.com left intact
{"id": "1", "podname": "reviews-66f8dddb8c-84pk6", "clustername": "null", "reviews": [{"reviewer": "Reviewer1", "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}}, {"reviewer": "Reviewer2", "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}}]}
```

## 在 TSB 中监视性能指标

你可以从 TSB 服务仪表板监视金丝雀和稳定 Pod 的每个服务实例的健康状况。

![显示稳定和金丝雀子集的服务仪表板](../../../assets/howto/gitops/subsets.png)

![子集金丝雀和稳定的服务实例度量](../../../assets/howto/gitops/service-metrics.png)

![显示只有 reviews-canary 调用 ratings-v1 服务的服务拓扑图](../../../assets/howto/gitops/topology.png)

## 金丝雀分析和自动升级

正如我们在 `rollout` 对象中配置的，金丝雀 `analysis` 将从第二阶段开始运行，因为它等待第一阶段在 10 分钟内完成以构建一些度量标准。从第二阶段开始，将执行 `AnalysisRun`，即 `AnalysisTemplate` 的一个实例化，根据配置的 `interval`。对于每次完成的运行，根据 `AnalysisTemplate` 中配置的最大 `failureLimit` 的状态，Argo 决定是否升级/回滚金丝雀部署。

### 金丝雀分析期间

```bash
kubectl argo rollouts promote reviews-rollout --full -n bookinfo
```

结果

```
Name:            reviews-rollout
Namespace:       bookinfo
Status:          ॥ Paused
Message:         CanaryPauseStep
Strategy:        Canary
  Step:          5/10
  SetWeight:     40
  ActualWeight:  40
Images:          docker.io/istio/examples-bookinfo-reviews-v1:1.16.4 (stable)
                 docker.io/istio/examples-bookinfo-reviews-v2:1.16.4 (canary)
Replicas:
  Desired:       5
  Current:       7
  Updated:       2
  Ready:         7
  Available:     7

NAME                                         KIND         STATUS     AGE   INFO
⟳ reviews-rollout                            Rollout      ॥ Paused   24m
├──# revision:2
│  ├──⧉ reviews-rollout-867b9c9bcb           ReplicaSet   ✔ Healthy  18m   canary
│  │  ├──□ reviews-rollout-867b9c9bcb-86mbt  Pod          ✔ Running  18m   ready:2/2
│  │  └──□ reviews-rollout-867b9c9bcb-9ghh2  Pod          ✔ Running  3m4s  ready:2/2
│  └──α reviews-rollout-867b9c9bcb-2         AnalysisRun  ◌ Running  8m4s  ✔ 2
└──# revision:1
   └──⧉ reviews-rollout-5d9dc876c9           ReplicaSet   ✔ Healthy  24m   stable
      ├──□ reviews-rollout-5d9dc876c9-27mth  Pod          ✔ Running  24m   ready:2/2
      ├──□ reviews-rollout-5d9dc876c9-8qqpx  Pod          ✔ Running  24m   ready:2/2
      ├──□ reviews-rollout-5d9dc876c9-9bqbv  Pod          ✔ Running  24m   ready:2/2
      ├──□ reviews-rollout-5d9dc876c9-cgxgd  Pod          ✔ Running  24m   ready:2/2
      └──□ reviews-rollout-5d9dc876c9-d447w  Pod          ✔ Running  24m   ready:2/2
```

### 成功升级后

一旦所有步骤都以 `successfull` 的分析运行方式执行完毕，Argo 将完全将图像升级到版本 `v2` 并将其标记为 `stable`。

```bash
kubectl argo rollouts get rollout reviews-rollout --watch -n bookinfo
```

## 手动升级金丝雀部署

你可以执行逐步升级，这将按照 Rollout 中列出的下一步骤进行操作，并最终完全升级新版本，或者你可以执行完整升级到所需版本，跳过分析、暂停和步骤。

```bash
# 逐步升级
kubectl argo rollouts promote reviews-rollout -n bookinfo

# 完整升级
kubectl argo rollouts promote reviews-rollout --full -n bookinfo
```

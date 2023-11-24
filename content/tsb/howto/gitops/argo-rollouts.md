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
名称：               bookinfo-app
项目：              默认
服务器：            https://kubernetes.default.svc
命名空间：          bookinfo
URL：                https://localhost:8080/applications/bookinfo-app
仓库：               https://github.com/tetrateio/tsb-gitops-demo.git
目标：
路径：               argo/app
同步窗口：         允许同步
同步策略：         自动
同步状态：         已同步到（1ba8e2d）
健康状态：         健康

组    类型                 命名空间  名称                    状态          健康  钩子  消息
       命名空间       bookinfo   bookinfo                运行中   已同步           命名空间/bookinfo 已创建
       ServiceAccount   bookinfo   bookinfo-details       已同步               serviceaccount/bookinfo-details 已创建
       ServiceAccount   bookinfo   bookinfo-productpage   已同步               serviceaccount/bookinfo-productpage 已创建
       ServiceAccount   bookinfo   bookinfo-ratings       已同步               serviceaccount/bookinfo-ratings 已创建
       ServiceAccount   bookinfo   bookinfo-reviews       已同步               serviceaccount/bookinfo-reviews 已创建
       Service            bookinfo   productpage            已同步   健康           service/productpage 已创建
       Service            bookinfo   details                已同步   健康           service/details 已创建
       Service            bookinfo   ratings                已同步   健康           service/ratings 已创建
       Service            bookinfo   reviews                已同步   健康           service/reviews 已创建
apps   Deployment         bookinfo   ratings-v1             已同步   健康           deployment.apps/ratings-v1 已创建
apps   Deployment         bookinfo   productpage-v1         已同步   健康           deployment.apps/productpage-v1 已创建
apps   Deployment         bookinfo   reviews                不同步   健康           deployment.apps/reviews 已创建
apps   Deployment         bookinfo   details-v1             已同步   健康           deployment.apps/details-v1 已创建
       命名空间                     bookinfo                已同步
```

## 应用程序设置

如果你已经为部署和服务资源创建了 Kubernetes 清单，你可以选择保留相同的对象以及 Argo `Rollout` 对象，以便实现金丝雀部署。
你可以对 `Rollout` 对象和 Istio VirtualService/DestinationRule 的 TSB 网格配置进行必要的更改，以实现所需的结果。

## TSB 配置设置

由于 Argo Rollout 要求你根据 Istio 的金丝雀部署策略约定对 Istio `VirtualService` 和 `DestinationRule` 对象进行一些修改，因此你可以使用 TSB `DIRECT` 模式配置来实现所需的结果。

* 根据 Argo Rollout 约定，需要在 TSB 直接模式资源（如 `VirtualService` 和 `DestinationRule`）中配置 2 个子集，分别命名为 `stable` 和 `canary`，并添加必要的标签，以识别 `canary` 和 `stable` pod。
* 请确保根据 Istio 约定为 TSB 配置识别子集并在服务仪表板中

启用指标。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-vs
  namespace: bookinfo
spec:
  hosts:
    - bookinfo
  http:
    - route:
        - destination:
            host: bookinfo
            subset: stable # 将 stable 子集设置为稳定版本
          weight: 100
        - destination:
            host: bookinfo
            subset: canary # 将 canary 子集设置为金丝雀版本
          weight: 0
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-dr
  namespace: bookinfo
spec:
  host: bookinfo
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
```

配置完成后，你可以使用 Argo Rollout 控制金丝雀部署并监控 SkyWalking 提供的指标。

这就是如何在 Argo Rollout 和 SkyWalking 的帮助下实现金丝雀分析和渐进式交付的基本步骤。希望这对你有所帮助！如果你有任何问题或需要进一步的指导，请随时提问。
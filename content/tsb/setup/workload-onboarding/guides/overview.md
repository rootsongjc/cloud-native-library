---
title: 概览
description: 工作负载载入概述。
weight: 1
---

当你在 Kubernetes 上部署工作负载时，以下操作会在背后自动进行：

1. Istio Sidecar 会部署在你的工作负载旁边。
2. 该 Sidecar 会配置工作负载的位置和其他所需元数据。

然而，当你将工作负载部署在独立的虚拟机之外时，
你必须自己处理这些事情。

工作负载载入功能为你解决了这个问题。
使用此功能，你只需执行以下步骤，即可将部署在虚拟机上的工作负载引入到网格中：

1. 在目标虚拟机上安装 Istio Sidecar（通过 DEB/RPM 软件包）。
2. 在目标虚拟机上安装 Workload Onboarding Agent（同样通过 DEB/RPM 软件包）。
3. 提供一个最小的、声明性的配置，描述在哪里引入工作负载，例如：

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:                            # 连接至
  host: onboarding-endpoint.your-company.corp
workloadGroup:                                 # 加入至
  namespace: bookinfo
  name: ratings
```

## 组件和工作流程

工作负载载入包括以下组件：

| 组件                         | 描述                                                         |
| ---------------------------- | ------------------------------------------------------------ |
| Workload Onboarding Operator | 安装到你的 Kubernetes 集群中作为 TSB 控制平面的一部分        |
| Workload Onboarding Agent    | 需要安装到你的虚拟机工作负载旁边的组件                       |
| Workload Onboarding Endpoint | Workload Onboarding Agent 将连接注册工作负载并获取 Istio Sidecar 的引导配置的组件 |

下图概述了完整的载入流程：

![虚拟机工作负载载入流程](../../../../assets/setup/workload_onboarding/workload-onboarding-overview.svg)

`Workload Onboarding Agent` 根据用户提供的声明性配置执行载入流程。

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:                           # (1)
  host: onboarding-endpoint.your-company.corp
workloadGroup:                                # (2)
  namespace: bookinfo
  name: ratings
```

根据上述配置，以下操作将发生：

1. Workload Onboarding Agent 将连接到 Workload Onboarding Endpoint
   在 `https://onboarding-endpoint.your-company.corp:15443` (1)
2. Workload Onboarding Endpoint 将使用 VM 的云特定凭据对连接的 Agent 进行身份验证
3. Workload Onboarding Endpoint 将决定是否允许具有此标识（即 VM 的标识）的工作负载加入特定的 `WorkloadGroup`（2）
4. Workload Onboarding Endpoint 将在 Istio 控制平面上注册一个新的 WorkloadEntry 以表示工作负载
5. Workload Onboarding Endpoint 将生成启动 Istio Proxy 所需的引导配置，根据相应的 `WorkloadGroup` 资源 (2)
6. Workload Onboarding Agent 将保存返回的引导配置到磁盘，并启动 Istio Sidecar
7. Istio Sidecar 将连接到 Istio 控制平面并接收其运行时配置

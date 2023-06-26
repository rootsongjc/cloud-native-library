---
weight: 12
title: "控制器指标"
linkTitle: "控制器指标"
date: '2023-06-21T16:00:00+08:00'
type: book
---

Argo Rollouts 控制器已经安装了[Prometheus 指标](https://prometheus.io/)，可以在 8090 端口的`/metrics`中获取。你可以使用这些指标查看控制器的健康状况，无论是通过仪表板还是通过其他 Prometheus 集成。

## 安装和配置 Prometheus

要利用指标，你需要在 Kubernetes 集群中安装 Prometheus。如果你没有现有的 Prometheus 安装，你可以使用任何常见的方法在你的集群中安装它。流行的选项包括[Prometheus Helm Chat](https://github.com/prometheus-community/helm-charts) 或 [Prometheus Operator](https://prometheus-operator.dev/)。

一旦 Prometheus 在你的集群中运行，你需要确保它抓取 Argo Rollouts 端点。Prometheus 已经包含了针对 Kubernetes 的服务发现机制，但你需要[首先进行配置](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)。根据你的安装方法，你可能需要采取其他操作来抓取 Argo Rollouts 端点。

例如，如果你使用了 Prometheus 的 Helm 图表，则需要使用以下注释标注你的 Argo Rollouts Controller：

```yaml
 spec:
   template:
     metadata:
       annotations:
         prometheus.io/scrape: "true"
         prometheus.io/path: /metrics
         prometheus.io/port: "8090"
```

你始终可以在 Prometheus“目标”屏幕中查看控制器是否成功到达：

一旦你的 Prometheus 实例读取了控制器指标，你可以像使用任何其他 Prometheus 数据源一样使用它们。

## 创建 Grafana Dashboard

你可以使用[Grafana](https://grafana.com/) Dashboard 轻松可视化控制器的指标。在集群中[安装 Grafana](https://grafana.com/docs/grafana/latest/installation/kubernetes/)并[将其连接到 Prometheus 实例](https://prometheus.io/docs/visualization/grafana/)。然后，你可以使用可用指标（在下一节中详细描述）创建任何仪表板。

作为起点，你可以在[这里](https://github.com/argoproj/argo-rollouts/blob/master/examples/dashboard.json)中找到现有的 dashboard。

你可以将此 dashboard 作为 JSON 文件[导入到 Grafana 安装中](https://grafana.com/docs/grafana/latest/dashboards/export-import/#importing-a-dashboard)。

## Rollout 对象的可用指标

Argo Rollouts 控制器发布了有关 Argo Rollout 对象的以下 Prometheus 指标。

| 名称                              | 描述                                          |
| --------------------------------- | --------------------------------------------- |
| rollout_info                      | 关于发布的信息。                              |
| rollout_info_replicas_available   | 每个发布可用的副本数。                        |
| rollout_info_replicas_unavailable | 每个发布不可用的副本数。                      |
| rollout_info_replicas_desired     | 每个发布所需的副本数。                        |
| rollout_info_replicas_updated     | 每个发布更新的副本数。                        |
| rollout_phase                     | [已弃用 - 使用 rollout_info]关于发布状态的信息。 |
| rollout_reconcile                 | 发布和调解表现。                              |
| rollout_reconcile_error           | 发布期间发生的错误。                          |
| experiment_info                   | 有关实验的信息。                              |
| experiment_phase                  | 有关实验状态的信息。                          |
| experiment_reconcile              | 实验和调解表现。                              |
| experiment_reconcile_error        | 实验期间发生的错误。                          |
| analysis_run_info                 | 有关分析运行的信息。                          |
| analysis_run_metric_phase         | 有关分析运行中特定指标的持续时间的信息。      |
| analysis_run_metric_type          | 有关分析运行中特定指标类型的信息。            |
| analysis_run_phase                | 有关分析运行状态的信息。                      |
| analysis_run_reconcile            | 分析运行和调解表现。                          |
| analysis_run_reconcile_error      | 分析运行期间发生的错误。                      |

## 控制器本身的可用指标

控制器还发布以下 Prometheus 指标，以描述控制器的健康状况。

| 名称                                        | 描述                                                         |
| ------------------------------------------- | ------------------------------------------------------------ |
| controller_clientset_k8s_request_total      | 在应用程序调解期间执行的 kubernetes 请求数量。                 |
| workqueue_adds_total                        | 工作队列处理的总添加数                                       |
| workqueue_depth                             | 工作队列的当前深度                                           |
| workqueue_queue_duration_seconds            | 项目在被请求之前在工作队列中停留的时间（以秒为单位）。       |
| workqueue_work_duration_seconds             | 从工作队列处理项目所需的时间（以秒为单位）。                 |
| workqueue_unfinished_work_seconds           | 进行中且未被 work_duration 观察到的工作所花费的时间（以秒为单位）。大的值表明卡住的线程。可以通过观察它增加的速度来推断卡住的线程数。 |
| workqueue_longest_running_processor_seconds | 处理工作队列的最长运行处理器的时间                           |
| workqueue_retries_total                     | 工作队列处理的总重试数                                       |

此外，Argo-rollouts 提供了有关 CPU、内存和文件描述符使用情况以及当前 Go 进程的进程启动时间和内存统计信息的指标。

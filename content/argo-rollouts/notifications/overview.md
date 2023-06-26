---
weight: 1
linkTitle: 概览
title: 通知
date: '2023-06-21T16:00:00+08:00'
type: book
---

🔔 重要提示：自版本 1.1 起可用。

Argo Rollouts 提供通知功能，由[Notifications Engine](https://github.com/argoproj/notifications-engine)支持。控制器管理员可以利用灵活的触发器和模板系统来配置终端用户请求的通知。终端用户可以通过在 Rollout 对象中添加注释来订阅配置的触发器。

## 配置

触发器定义了通知应该在何时发送以及通知内容模板。默认情况下，Argo Rollouts 附带了一系列内置触发器，涵盖了 Argo Rollout 生命周期的最重要事件。触发器和模板都在`argo-rollouts-notification-configmap` ConfigMap 中配置。为了快速入门，你可以使用在[notifications-install.yaml](https://github.com/argoproj/argo-rollouts/blob/master/manifests/notifications-install.yaml)中定义的预配置通知模板。

如果你正在利用 Kustomize，则建议将[notifications-install.yaml](https://github.com/argoproj/argo-rollouts/blob/master/manifests/notifications-install.yaml)作为远程资源包含在你的`kustomization.yaml`文件中：

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
- https://github.com/argoproj/argo-rollouts/releases/latest/download/notifications-install.yaml
```

在包含`argo-rollouts-notification-configmap` ConfigMap 之后，管理员需要配置与所需通知服务（例如 Slack 或 MS Teams）的集成。下面的示例演示了 Slack 集成：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-notification-configmap
 data:
   # 模板的详细信息被省略
   # 触发器的详细信息被省略
   service.slack: |
     token: $slack-token
 ---
 apiVersion: v1
 kind: Secret
 metadata:
   name: argo-rollouts-notification-secret
 stringData:
   slack-token: <my-slack-token>
```

有关支持的服务和配置设置的更多信息，请参见[服务文档](https://argo-rollouts.readthedocs.io/en/stable/generated/notification-services/overview/)。

## 默认触发器模板

目前，以下触发器具有[内置模板](https://github.com/argoproj/argo-rollouts/tree/master/manifests/notifications)。

- `on-rollout-completed`当一个 rolling rollout 结束并且所有步骤都已完成时
- `on-rollout-step-completed`当滚动部署定义中的单个步骤已完成时
- `on-rollout-updated`当 Rollout 定义更改时
- `on-scaling-replica-set`当 Rollout 中的副本数更改时

## 订阅

终端用户可以使用`notifications.argoproj.io/subscribe.<trigger>.<service>: <recipient>`注释开始使用通知。例如，以下注释订阅了两个 Slack 频道，以通知有关金丝雀滚动步骤完成的信息：

```yaml
 ---
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 metadata:
   name: rollout-canary
   annotations:
     notifications.argoproj.io/subscribe.on-rollout-step-completed.slack: my-channel1;my-channel2
```

注释键由以下部分组成：

- `on-rollout-step-completed` - 触发器名称
- `slack` - 通知服务名称
- `my-channel1;my-channel2` - 一个由分号分隔的收件人列表

## 定制

Rollout 管理员可以通过配置通知模板和自定义触发器来自定义通知`argo-rollouts-notification-configmap` ConfigMap。

### 模板

通知模板是生成通知内容的无状态函数。该模板利用[html/template](https://golang.org/pkg/html/template/) golang 包。它旨在可重用，并且可以被多个触发器引用。

以下示例演示了样本模板：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-notification-configmap
 data:
   template.my-purple-template: |
     message: |
       Rollout {{.rollout.metadata.name}} has purple image
     slack:
         attachments: |
             [{
               "title": "{{ .rollout.metadata.name}}",
               "color": "#800080"
             }]
```

每个模板都可以访问以下字段：

- `rollout`保存 rolling rollout 对象。
- `recipient`保存收件人名称。

模板定义的`message`字段允许为任何通知服务创建基本通知。你可以利用特定于通知服务的字段来创建复杂的通知。例如，使用特定于服务的你可以为 Slack 添加块和附件，为电子邮件添加主题或 URL 路径，为 Webhook 添加正文。有关更多信息，请参见相应的服务文档。

### 自定义触发器

除了自定义通知模板外，管理员还可以配置自定义触发器。自定义触发器定义了发送通知的条件。定义包括名称、条件和通知模板引用。条件是返回 true 如果应发送通知的谓词表达式。触发器条件评估由[antonmedv/expr](https://github.com/antonmedv/expr)支持。条件语言语法在[Language-Definition.md](https://github.com/antonmedv/expr/blob/master/docs/Language-Definition.md)中描述。

触发器在`argo-rollouts-notification-configmap` ConfigMap 中配置。例如，以下触发器在 rolling rollout pod 规范使用`argoproj/rollouts-demo:purple`镜像时发送通知：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-notification-configmap
 data:
   trigger.on-purple: |
     - send: [my-purple-template]
       when: rollout.spec.template.spec.containers[0].image == 'argoproj/rollouts-demo:purple'
```

每个条件可能使用多个模板。通常，每个模板负责生成特定于服务的通知部分。

### 通知度量

在 argo-rollouts 中启用通知时，将发出以下 prometheus 度量标准。

- notification_send_success 是计算成功发送通知的计数器。
- notification_send_error 是计算发送通知失败的计数器。
- notification_send 是测量发送通知性能的直方图。

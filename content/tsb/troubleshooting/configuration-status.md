---
title: 配置状态故障排除
description: 使用 tctl 了解 TSB 配置的部署状态。
weight: 3
---

Tetrate Service Bridge 的 tctl CLI 允许你与 TSB API 交互以应用对象的配置。本文档介绍如何使用 tctl 了解系统中资源配置的部署状态。

## 资源状态

TSB 通过 ResourceStatus 跟踪配置更改的生命周期。你可以使用 [tctl x status](../../reference/cli/reference/experimental#tctl-experimental-status) 获取它们。运行 `tctl x status --help` 可查看所有可能的选项。

根据资源的配置状态计算方式，有不同类型的资源。

| 资源类型           | 配置状态                           | 示例                                                         |
| ------------------ | ---------------------------------- | ------------------------------------------------------------ |
| 父资源             | 聚合其子资源的状态。               | `workspace`, `trafficgroup`, `gatewaygroup`, `securitygroup` |
| 子资源             | 不依赖于其他资源。                 | `ingressgateway`, `egressgateway`, `trafficsettings` 等      |
| 不可配置资源       | 不会直接在目标集群中实体化为配置。 | `organizations`, `tenants`, `users`                          |
| 具有依赖关系的资源 | 高级别资源。                       | `applications` 和 `apis`                                     |

资源状态可以具有多个值，这取决于其配置在[TSB 组件](../../concepts/architecture)中的传播程度。

| 类型                 | 状态       | 条件                                                         |
| -------------------- | ---------- | ------------------------------------------------------------ |
| 子资源和不可配置资源 | `ACCEPTED` | 它们的配置已经通过验证并持久化。这是对有效配置的初始值。     |
|                      | `READY`    | 它们的配置已传播到所有目标集群。这也是不可配置资源的默认状态。 |
|                      | `PARTIAL`  | 其中一些配置在某些目标集群中是就绪的，但在其中一些目标集群中不是。 |
|                      | `FAILED`   | 它们的配置在一些或所有目标集群中触发了一些内部错误。         |
|                      | `FAILED`   | 目标集群中的某个问题资源会影响配置的正确行为。               |
|                      |            |                                                              |
| 父资源               | `ACCEPTED` | 它们的所有子资源都是 `ACCEPTED` 或 `READY`。                 |
|                      | `READY`    | 它们的所有子资源都是 `READY`。                               |
|                      | `FAILED`   | 它们的任何子资源都是 `FAILED`。                              |
|                      |            |                                                              |
| 具有依赖关系的资源   | `ACCEPTED` | 其所有依赖配置都是 `ACCEPTED`。                              |
|                      | `READY`    | 其所有依赖配置都是 `READY`。                                 |
|                      | `DIRTY`    | 其所有依赖配置都是 `DIRTY`。                                 |
|                      | `FAILED`   | 其任何依赖配置都是 `FAILED`。                                |
|                      | `PARTIAL`  | 其依赖配置处于 `READY`, `ACCEPTED` 和/或 `DIRTY` 的混合状态。 |

你可以在 [状态 API 规范](../../refs/tsb/v2/status#status) 中了解更多关于状态类型的信息。

## 使用 tctl 了解配置对象的状态

让我们在部署了 `bookinfo` 应用程序的情况下，看看一些示例。

{{<callout note 提示>}}
我们假设 Bookinfo 应用程序已在其自己的工作区中部署，就像在我们的 [快速入门](../../quickstart/introduction) 教程中一样，并已配置相应的组。
{{</callout>}}

你可以使用 `tctl x status` 检查 `bookinfo` 入口网关的状态：

```bash
$ tctl x status ig --tenant tetrate --workspace bookinfo --gatewaygroup bookinfo bookinfo
NAME        STATUS      LAST EVENT      MESSAGE
bookinfo    ACCEPTED    XCP_ACCEPTED
```

这显示其配置已被验证并持久化。

如果你想获取更多信息，它的 YAML 版本将显示此资源状态的事件历史记录。这些信息对于排查资源配置的生命周期非常有用。

```bash
$ tctl x status ig --tenant tetrate --workspace bookinfo --gatewaygroup bookinfo bookinfo
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  group: bookinfo
  name: bookinfo
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo
spec:
  configEvents:
    events:
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-02-10T16:54:14.710165091Z"
      type: XCP_ACCEPTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-02-10T16:54:14.649002805Z"
      type: MPC_ACCEPTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-02-10T16:54:10.453242255Z"
      type: TSB_ACCEPTED
  status: ACCEPTED
```

在这里，你可以看到更改了最后一个版本 `sMlEWPbvm6M=` 的此 `ingressgateway` 资源的状态的事件历史记录，最近的事件排在最前面。

在此示例中，资源首先被 TSB 服务器接受，然后是 MPC，最后是 XCP 组件。

请注意，只有最新资源版本的历史记录会被保留。在接下来的部分中，你将学会如何使用审计日志来显示所有版本的历史记录。

## 使用 TSB 审计日志了解配置对象的生命周期

TSB 有一个称为审计日志的概念，显示了发生在 TSB 资源上的所有事件。谁在何时对每个资源进行了什么操作，它还可以提供有关其配置的不同阶段的见解。

例如，你可以使用以下命令获取在 bookinfo 工作区中发生的所有事件的列表以及其中包含的所有资源。

```bash
$ tctl x audit ws bookinfo --recursive --text bookinfo
TIME                   SEVERITY    TYPE                                        OPERATION               USER     MESSAGE
2022/02/10 17:02:53    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for trafficgroup "bookinfo" version "oxil15u6bfw="
2022/02/10 17:02:53    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for securitygroup "bookinfo" version "gEUA3cK7+YI="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for ingressgateway "bookinfo" version "sMlEWPbvm6M="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for trafficgroup "bookinfo" version "oxil15u6bfw="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for workspace "bookinfo" version "GBcgtWe3R80="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_REJECTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for gatewaygroup "bookinfo" version "y6q054gFZCQ="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for securitygroup "bookinfo" version "gEUA3cK7+YI="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for workspace "bookinfo" version "GBcgtWe3R80="
2022/02/10 17:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for gatewaygroup "bookinfo" version "y6q054gFZCQ="
2022/02/10 17:02:48    INFO        gateway.tsb.tetrate.io/v2/IngressGateway    create                  admin    Create IngressGateway "bookinfo" by "admin"
```

审核日志中标识了一些错误，你可以通过检索那些对象的配置状态的详细信息来进一步检查这些错误：

```bash
$ tctl x status ig --workspace bookinfo --gatewaygroup bookinfo bookinfo
NAME        STATUS    LAST EVENT              MESSAGE
bookinfo    FAILED    XCP_CENTRAL_REJECTED    admission webhook "central-validation.xcp.tetrate.io" denied the request: configuration is invalid: domain name "tetrate.io---" invalid (label "io---" invalid)
```

正如你在命令输出中所看到的，配置已被 XCP 组件拒绝，并标记为无效，它将不会传播到目标集群。

你还可以通过查询工作区的状态来获取见解。它将显示其子资源中的任何错误。通过这种方式，从任何工作区或顶级元素轻松导航到配置对象可能存在的特定错误非常容易。

```bash
$ tctl x status ws bookinfo
NAME        STATUS    LAST EVENT    MESSAGE
bookinfo    FAILED                  The following children are failing: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo
```

或其扩展的 YAML 版本：

```bash
$ tctl x status ws bookinfo -o yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: bookinfo
  organization: tetrate
  tenant: tetrate
spec:
  aggregatedStatus:
    children:
      organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo:
        message: 'The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo'
        status: FAILED
      organizations/tetrate/tenants/tetrate/workspaces/bookinfo/securitygroups/bookinfo:
        status: ACCEPTED
      organizations/tetrate/tenants/tetrate/workspaces/bookinfo/trafficgroups/bookinfo:
        status: ACCEPTED
    configEvents:
      events:
      - etag: '"GBcgtWe3R80="'
        timestamp: "2022-02-10T18:32:29.593869622Z"
        type: XCP_ACCEPTED
      - etag: '"GBcgtWe3R80="'
        timestamp: "2022-02-10T18:32:29.576374660Z"
        type: MPC_ACCEPTED
      - etag: '"GBcgtWe3R80="'
        timestamp: "2022-02-10T18:32

:24.679197258Z"
        type: TSB_ACCEPTED
  message: 'The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo'
  status: FAILED
```

最后，审计日志帮助轻松识别配置问题是何时引入的，以及在任何时间点应用的确切更改。在这里，你可以清楚地看到一个对管理员的更新触发了配置资源的更改，并且可以看到导致问题的确切字段：

```bash
$ tctl x audit ig --workspace bookinfo --gatewaygroup bookinfo bookinfo
TIME                   SEVERITY    TYPE                                        OPERATION               USER     MESSAGE
2022/02/10 22:04:14    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_REJECTED    mpc      New FAILED status due to XCP_CENTRAL_REJECTED event for ingressgateway "bookinfo" version "O0HhTEHkvjA="
2022/02/10/22:04:14    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for ingressgateway "bookinfo" version "O0HhTEHkvjA="
2022/02/10 22:04:12    INFO        gateway.tsb.tetrate.io/v2/IngressGateway    update                  admin    Update IngressGateway "bookinfo" by "admin"
2021/11/25 16:02:53    INFO        api.tsb.tetrate.io/v2/ResourceStatus        XCP_CENTRAL_ACCEPTED    mpc      New ACCEPTED status due to XCP_CENTRAL_ACCEPTED event for ingressgateway "bookinfo" version "sMlEWPbvm6M="
2021/11/25 16:02:52    INFO        api.tsb.tetrate.io/v2/ResourceStatus        MPC_ACCEPTED            mpc      New ACCEPTED status due to MPC_ACCEPTED event for ingressgateway "bookinfo" version "sMlEWPbvm6M="
2021/11/25 16:02:48    INFO        gateway.tsb.tetrate.io/v2/IngressGateway    create                  admin    Create IngressGateway "bookinfo" by "admin"
```

以日期过滤器显示 yaml 将输出：

```bash
$ tctl x audit ig --workspace bookinfo --gatewaygroup bookinfo bookinfo --operation update --since "2022/02/10 22:04:12" -o yaml
apiVersion: audit.tetrate.io/v1
kind: AuditLog
metadata: {}
spec:
  createTime: "2021-12-13T22:11:32Z"
  fqn: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo
  kind: gateway.tsb.tetrate.io/v2/IngressGateway
  message: Update IngressGateway "bookinfo" by "admin"
  operation: update
  properties:
    diff: |2-
       {
        Fqn: "organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo",
      - Etag: "\"sMlEWPbvm6M=\"",
      + Etag: "\"O0HhTEHkvjA=\"",
        WorkloadSelector: {
         Namespace: "bookinfo",
         Labels: {
          app: "bookinfo-gateway",
         },
        },
        Http: [
         {
      -   Name: "productpage",
      +   Name: "productpage-invalid",
          Port: 80,
      -   Hostname: "bookinfo.tetrate.io",
      +   Hostname: "bookinfo.tetrate.io=--",
          Routing: {
           Rules: [
            {
             RouteOrRedirect: {
              Route: {
               Host: "bookinfo/productpage.bookinfo.svc.cluster.local",
               Port: 9080,
              },
             },
            },
           ],
          },
         },
        ],
       }
    display-name: ""
    etag: '"O0HhTEHkvjA="'
    fqn: organizations/tetrate/tenants/tetrate/workspaces/bookinfo/gatewaygroups/bookinfo/ingressgateways/bookinfo
  severity: INFO
  triggeredBy: admin
```

你可以很容易地以 `diff` 格式看到确切更改的字段。


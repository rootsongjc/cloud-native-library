---
title: TSB 中的 GitOps
description: 如何在 TSB 中使用 GitOps 工作流进行应用配置。
weight: 1
---

本文档解释了如何在 TSB 中使用 GitOps 工作流。该文档假设[已在管理平面集群](../../../operations/features/configure-gitops)和/或应用程序集群中启用了 GitOps。

TSB 中 GitOps 支持的主要思想是允许：
- 管理员团队可以直接在管理平面集群中创建 TSB 配置资源。
- 应用程序团队可以直接在应用程序集群中创建 TSB 配置资源。

应用程序团队可以像推送应用程序本身的更改一样推送应用程序配置的更改，并允许将应用程序部署资源和 TSB 配置打包在一起，例如在同一个 Helm 图中。

为了实现这一点，所有 TSB 配置对象都存在于 Kubernetes 自定义资源定义（CRD）中，以便可以轻松应用于集群。如下图所示，一旦资源应用到集群中，它们将被自动协调并转发到管理平面。

![TSB 中基于 Flux 的 GitOps 示意图](../../../assets/operations/gitops.svg)

## TSB Kubernetes 自定义资源

用于 TSB 配置的 Kubernetes 自定义资源与任何其他 Kubernetes 资源一样。以下示例显示了一个 `Workspace` 定义：

```yaml
apiVersion: tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: bookinfo
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: engineering
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
```

它们与你可以使用 [tctl 应用](../../reference/cli/reference/apply)的资源非常相似，不同之处在于：

* `spec` 的内容在 [YAML API 参考](../../reference/yaml-api)中定义。规格与你在 `tctl` 中使用的规格相同。
* 元数据部分不具有 TSB 属性，如 `organization`、`tenant` 等。相反，必须使用以下适当的注释提供层次结构信息：
  * _tsb.tetrate.io/organization_
  * _tsb.tetrate.io/tenant_
  * _tsb.tetrate.io/workspace_
  * _tsb.tetrate.io/trafficGroup_
  * _tsb.tetrate.io/securityGroup_
  * _tsb.tetrate.io/gatewayGroup_
  * _tsb.tetrate.io/istioInternalGroup_
  * _tsb.tetrate.io/application_
* 除以下内容之外，`apiVersion` 和 `kind` 属性对于所有资源都是相同的：
  * API 组 `api.tsb.tetrate.io/v2` 改为 `tsb.tetrate.io/v2`。

请参阅 [TSB Kubernetes API](../../../reference/k8s-api/guide) 以下载 TSB Kubernetes CRD。

## 使用 Istio 直连模式资源

在使用 GitOps 与 Istio 直连模式资源时，需要为资源添加一个附加标签：

```yaml
labels:
    istio.io/rev: "tsb"
```

例如，在 Gateway 组中的 Gateway 对象如下所示：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: bookinfo-gateway
  namespace: bookinfo
  labels:
    istio.io/rev: tsb
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tetrate
    tsb.tetrate.io/workspace: bookinfo
    tsb.tetrate.io/gatewayGroup: bookinfo
spec:
  selector:
    app: tsb-gateway-bookinfo
  servers:
    - hosts:
        - "bookinfo.tetrate.io"
      port:
        number: 80
        name: http
        protocol: HTTP
```

这是为了防止集群中正在运行的 Istio 立即处理该资源，因为它只应该由 TSB 中继读取，然后推送到管理平面。有一个验证 Webhook 将检查所有需要此标签的资源，如果缺少它，则会拒绝它们。

## 应用 TSB 自定义资源

TSB 自定义资源可以使用 `kubectl` 正常应用。例如，要应用上面示例中的工作区，你只需运行：

```bash
kubectl apply -f workspace.yaml

kubectl get workspaces -A
NAMESPACE   NAME       PRIVILEGED   TENANT    AGE
bookinfo    bookinfo                engineering   4m20s
```

如果你想要验证对象是否已在管理平面中正确创建，你也可以使用 `tctl` 在那里查看对象：

```bash
$ tctl get ws bookinfo
NAME        DISPLAY NAME    DESCRIPTION
bookinfo
```

## 与持续部署解决方案集成

TSB GitOps 功能允许你轻松将 TSB 配置工作流与 CI/CD 解决方案集成。以下页面提供了一些配置示例，你可以按照这些示例来了解它的工作原理：

* [配置 Flux CD 以在 TSB 中使用 GitOps](../flux)

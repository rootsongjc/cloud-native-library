---
draft: false
title: "ApplicationSet 安全性"
linktitle: "安全"
weight: 5
---

在使用 ApplicationSet 之前，了解其安全性影响非常重要。

## 只有管理员可以创建/更新/删除 ApplicationSet

ApplicationSet 可以在任意 Project 下创建应用程序。Argo CD 设置通常包括高权限的 [Project](../../user-guide/projects/)（例如 `default`），往往包括管理 Argo CD 自身资源的能力（例如 RBAC ConfigMap）。

ApplicationSets 还可以快速创建任意数量的应用程序，并同样快速删除它们。

最后，ApplicationSets 可以显示特权信息。例如，[git generator](../generators-git/) 可以读取 Argo CD 命名空间中的 Secrets，并将其作为 Auth 标头发送到任意 URL（例如为 `api` 字段提供的 URL）。 （此功能旨在为 SCM 提供程序（如 GitHub）授权请求，但可能会被恶意用户滥用。）

出于这些原因，**只有管理员**可以通过 Kubernetes RBAC 或任何其他机制获得创建、更新或删除 ApplicationSets 的权限。

## **管理员必须为 ApplicationSets 的真实来源应用适当的控制**

即使非管理员不能创建 ApplicationSet 资源，他们也可能影响 ApplicationSets 的行为。

例如，如果 ApplicationSet 使用 [git generator](../generators-git/)，则具有源 Git 存储库的推送访问权限的恶意用户可能会生成过多的应用程序，对 ApplicationSet 和应用程序控制器造成压力。他们还可能导致 SCM 提供者的速率限制生效，影响 ApplicationSet 服务。

### **模板化的“project”字段**

特别需要注意使用模板化的“project”字段的 ApplicationSet。具有写权限的恶意用户（例如，具有对 git generator 的 git repo 的推送访问权限的用户）可能会在限制不足的 Projects 下创建应用程序。具有在不受限制的 Project（如“default”Project）下创建应用程序的能力的恶意用户可能会通过修改其 RBAC ConfigMap 等方式接管 Argo CD 本身。

如果 ApplicationSet 的模板中未硬编码“project”字段，则管理员*必须*控制 ApplicationSet 的生成器的所有来源。

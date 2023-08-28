---
title: 配置权限
weight: 6
---

在本部分中，你将了解如何使用 TSB 中的 `AccessBindings` 配置访问策略来管理不同团队和用户的权限。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。
- 创建租户和工作区。
-  创建配置组。

## 授予团队对工作区的完全访问权限

你将配置一个访问策略，授予团队对工作区的完全访问权限。团队成员将能够创建并完全管理工作区中的资源，但无法修改工作区对象本身。这将通过分配 `Creator` 角色来实现。

1. 在左侧面板的“租户”下，选择“工作区”。
2. 单击所需的工作区以访问其详细信息页面。
3. 单击权限选项卡。
4. 选择“按团队”选项可查看团队列表。
5. 找到并单击所需团队右侧的编辑图标。
6. 选择 `Creator` 角色。
7. 单击右下角的保存更改按钮。

## 向组的用户授予写入权限

要向组的特定用户授予写入权限，请遵循类似的过程：

1. 导航到组的权限选项卡。
2. 选择“按用户”选项可查看用户列表。
3. 找到并单击所需用户旁边的编辑图标。
4. 选择 `Writer` 角色。
5. 单击右下角的保存更改按钮。

## 使用tctl

你还可以通过应用 YAML 文件中定义的 `AccessBindings` 使用 `tctl` 实现相同的配置：

使用工作区和流量组对象所需的 `AccessBindings` 创建以下 `access-policy.yaml` 文件：

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/tetrate/tenants/tetrate/workspaces/bookinfo-ws
spec:
  allow:
    - role: rbac/creator
      subjects:
        # Change the name of the team to the desired one
        - team: organizations/tetrate/teams/Platform
---
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/tetrate/tenants/tetrate/workspaces/bookinfo-ws/trafficgroups/bookinfo-traffic
spec:
  allow:
    - role: rbac/writer
      subjects:
        # Change the name of the user to the desired one
        - user: organizations/tetrate/users/zack
```

使用 `tctl` 应用策略：

```bash
tctl apply -f access-policy.yaml
```

通过执行这些步骤，你可以使用 `AccessBindings` 有效配置访问策略，以管理 TSB 环境中不同团队和用户的权限。

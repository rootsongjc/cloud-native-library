---
title: 用户同步
weight: 4
---

TSB 拥有一个 teamsync 组件，它会定期连接到你的身份提供者（IdP），并将用户和团队信息同步到 TSB 中。

目前，teamsync 支持[LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)和[Azure AD](https://azure.microsoft.com/services/active-directory/)，并会自动为你执行正确的操作。但是，如果你使用其他 IdP，你将需要手动执行这些任务。本文将描述如何执行这些任务。

在开始之前，请确保你已经：

- [安装了 TSB 管理平面](../../../setup/self-managed/management-plane-installation)
- 使用管理员帐户[登录到 TSB](../../../setup/tctl-connect)。
- 获取你的 TSB 的组织名称 - 确保使用在 TSB `ManagementPlane` CR 中配置的安装时的组织名称。

## 创建组织

Teamsync 不仅同步你的用户和团队，还会在首次运行 TSB 管理平面组件安装后创建一个组织。

因此，如果你使用的 IdP 不受 teamsync 支持，你还需要手动执行此步骤。

要创建一个组织，请创建以下`organization.yaml`文件，然后使用 tctl 应用它

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Organization
metadata:
  name: <organization-name>
```

```bash
tctl apply -f organization.yaml
```

## 手动同步用户和团队

同步涉及从 IdP 获取用户和团队信息，然后将它们转换为 TSB 同步 API 负载的结构，然后将同步请求发送到 TSB API 服务器。一旦它们被同步，你可以为用户和团队分配角色，以赋予它们访问 TSB 资源的权限。

![](../../../assets/operations/teamsync.png)

### 从 IdP 获取用户和团队

此步骤的详细信息将取决于你的 IdP。你应该查阅你的 IdP 文档，了解如何获取用户和团队。例如，如果你使用 Okta，你可以使用[List users](https://developer.okta.com/docs/reference/api/users/)和[List groups](https://developer.okta.com/docs/reference/api/groups/) API。类似地，如果你使用 Keycloak，你可以使用[List users](https://www.keycloak.org/docs-api/15.0/rest-api/index.html#_users_resource)和[List groups](https://www.keycloak.org/docs-api/15.0/rest-api/index.html#_groups_resource) API。

### 将数据转换为 TSB 同步 API 负载

一旦你从 IdP 获取用户和团队列表，你需要将它们转换为 TSB 同步 API 负载格式。如何执行此转换的确切细节取决于你的 IdP API 的负载格式。

以下是同步 API 负载的示例。有关更多详细信息，请参阅<a href="../../rest#tag/Organizations/operation/Organizations_SyncOrganization">同步组织 API</a>。

```json
{
    "sourceType": "MANUAL",
    "users": [
        {
            "id": "user_1_id",
            "email": "user_1@email.com",
            "loginName": "user1",
            "displayName": "用户 1"
        },
        {
            "id": "user_2_id",
            "email": "user_2@email.com",
            "loginName": "user2",
            "displayName": "用户 2"
        },
    ],
    "teams": [
        {
            "id": "team_1_id",
            "description": "团队 1 描述",
            "displayName": "团队 1",
            "memberUserIds": [
                "user_1_id"
            ]
        },
         {
            "id": "team_2_id",
            "description": "团队 2 描述",
            "displayName": "团队 2",
            "memberUserIds": [
                "user_2_id"
            ]
        },
    ]
}
```

### 发送同步 API 请求

在将 IdP 负载转换为 TSB 同步 API 负载后，你可以向 TSB API 服务器发送请求以同步数据。

以下示例使用`curl`向运行在`<tsb-host>:8443`上的 TSB API 服务器发送请求，使用 TSB 管理员用户凭据。假定 TSB 同步 API 负载存储在文件`/path/to/data.json`中

```bash
curl --request POST \
  --url https://<tsb-host>:8443/v2/organizations/tetrate/sync \
  --header 'Authorization: Basic base64(<admin>:<admin-password>) \
  --header 'Content-Type: application/json' \
  --data-binary '@/path/to/data.json'
```

### 自动化流程

现在你知道 teamsync 如何工作，你可以创建一个定期运行的服务（例如作为`cron`作业），使用你喜欢的编程语言来自动化同步过程。


这是关于 TSB 中用户同步的文档。TSB 有一个 teamsync 组件，用于定期连接到你的身份提供者（IdP），将用户和团队信息同步到 TSB 中。目前，teamsync 支持 LDAP 和 Azure AD，但如果你使用其他 IdP，需要手动执行同步任务。

在开始之前，确保你已经完成了以下步骤：
- 安装了 TSB 管理平面
- 使用管理员帐户登录到 TSB
- 获取了 TSB 的组织名称，这应该是在安装 TSB 时配置的组织名称。

首先，文档介绍了如何手动创建一个组织，因为 teamsync 在首次运行时会自动创建组织。然后，它详细描述了如何手动从 IdP 获取用户和团队信息，将其转换为 TSB 同步 API 负载格式，然后将其同步到 TSB。最后，文档提到可以自动化这个过程，例如使用定期运行的服务来自动同步用户和团队信息。
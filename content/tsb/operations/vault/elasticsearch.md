---
title: Elasticsearch 凭据
description: 如何将 Vault Agent Injector 与 Elasticsearch 结合使用。
weight: 2
---

在开始之前，你必须具备以下条件：
- Vault 1.3.1 或更新版本
- Vault Injector 0.3.0 或更新版本
- Elasticsearch 6.x 或 7.x，带有基本许可证或更高版本

## 设置 Vault

安装 Vault（不需要在 Kubernetes 集群中安装，但应该能够从 Kubernetes 集群内部访问）。必须将 Vault Injector（agent-injector）安装到集群中，并配置以注入 sidecar。Helm Chart `v0.5.0+` 会自动完成此操作，它安装了 Vault `0.12+` 和 Vault-Injector `0.3.0+`。下面的示例假设 Vault 安装在 `tsb` 命名空间中。

有关详细信息，请查看 [Vault 文档](https://www.vaultproject.io/docs/platform/k8s/injector/installation)。

```bash
helm install --name=vault --set='server.dev.enabled=true' ./vault-helm
```

## 启动启用安全性的 Elasticsearch

如果你管理自己的 Elasticsearch 实例，你需要启用安全性并设置超级用户密码。

## 为 Vault 创建角色

首先，使用超级用户身份，创建一个角色，该角色将允许 Vault 通过向 Elasticsearch 发送 POST 请求获得最低权限。

```bash
curl -k \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"cluster": ["manage_security"]}' \
    https://<超级用户用户名>:<超级用户密码>@<elastic-ip>:<elastic-port>/_xpack/security/role/vault
```

接下来，为 Vault 创建与该角色关联的用户。

```bash
curl -k \
    -X POST \
    -H "Content-Type: application/json" \
    -d @data.json \
    https://<超级用户用户名>:<超级用户密码>@<elastic-ip>:<elastic-port>/_xpack/security/user/vault
```

在此示例中，`data.json` 的内容如下：

```json
{
    "password": "<vault-elastic 密码>",
    "roles": ["vault"],
    "full_name": "Hashicorp Vault",
    "metadata": {
        "plugin_name": "Vault Plugin Database Elasticsearch",
        "plugin_url": "https://github.com/hashicorp/vault-plugin-database-elasticsearch"
    }
}
```

现在，已配置好 Elasticsearch 用户，可以被 Vault 使用。

## 为 Elasticsearch 设置数据库秘密引擎

在 Vault 中启用数据库秘密引擎。

```bash
vault secrets enable database
```

预期输出：
```text
Success! Enabled the database secrets engine at: database/
```

默认情况下，秘密引擎在与引擎同名的路径上启用。要在不同路径上启用秘密引擎，请使用 `-path` 参数。

使用插件和连接信息配置 Vault。你需要提供证书、密钥和 CA 捆绑（根 CA 和中间 CA）：

```bash
vault write database/config/tsb-elastic \
    plugin_name="elasticsearch-database-plugin" \
    allowed_roles="tsb-elastic-role" \
    username=vault \
    password=<vault-elastic密码> \
    url=https://<elastic-ip>:<elastic-port> \
    ca_cert=es-bundle.ca
```

配置一个将 Vault 中的名称映射到 Elasticsearch 中的角色定义的角色。

```bash
vault write database/roles/tsb-elastic-role \
    db_name=tsb-elastic \
    creation_statements='{"elasticsearch_role_definition": {"cluster":["manage_index_templates","monitor"],"indices":[{"names":["*"],"privileges":["manage","read","write"]}],"applications":[],"run_as":[],"metadata":{},"transient_metadata":{"enabled":true}}}' \
    default_ttl="1h" \
    max_ttl="24h"

Success! Data written to: database/roles/internally-defined-role
```

为验证配置，通过使用角色名称从 `/creds` 终端点生成新凭据：

```bash
vault read database/creds/tsb-elastic-role
Key                Value
---                -----
lease_id           database/creds/tsb-elastic-role/jZHuJvZeEOvGJhfFixVcwOyB
lease_duration     1h
lease_renewable    true
password           A1a-SkZ9KgF7BJGn2FRH
username           v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455
```

你可以检查 Elasticsearch 集群，以验证新创建的凭据是否存在：

```bash
curl -u "vault:<vault-elastic密码>" -ks -XGET https://<超级用户用户名>:<超级用户密码>@<elastic-ip>:<elastic-port>/_xpack/security/user/v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455|jq '.'

{
    "v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455": {
        "username": "v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455",
        "roles": [
            "v-root-tsb-elastic-rol-2eRGSeD09gTNzYHf7a2G-1610542455"
        ],
        "full_name": null,
        "email": null,
        "metadata": {},
        "enabled": true
    }
}
```

## 设置 Kubernetes 秘密引擎

配置一个名为 "database" 的策略，这是一个非常不受限制的策略，在生产环境中，我们应该更加安全。

```bash
vault policy write es-auth - <<EOF
path "database/creds/internally-defined-role" {
    capabilities = ["read"]
}
EOF
Success! Uploaded policy: es-auth
```

配置 Vault 以启用对 Kubernetes API 的访问。此示例假设你正在 Vault pod 中使用 `kubectl exec` 运行命令。如果不是这样，你需要找到正确的 JWT 令牌、Kubernetes API URL（Vault 将用于连接到 Kubernetes 的 URL）

以及 `vaultserver` 服务帐户的 CA 证书，如 [Vault 文档](https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes#define-a-kubernetes-service-account) 中所述。

```bash
vault auth enable kubernetes
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

将我们的数据库策略附加到将使用它的服务帐户上，即管理平面和控制平面命名空间的 OAP 服务帐户：

```bash
vault write auth/kubernetes/role/es \
    bound_service_account_names=tsb-oap,istio-system-oap,default \
    bound_service_account_namespaces=tsb,istio-system \
    policies=es-auth \
    ttl=1h
```

## 注入凭据到 Pod

### 管理平面

要在管理平面中与 Elasticsearch 一起使用 Vault Agent Injector，请向 `ManagementPlane` 自定义资源添加以下部署 pod 注释和环境变量。

```yaml
spec:
  components:
    oap:
      kubeSpec:
        deployment:
          env:
            - name: SW_ES_SECRETS_MANAGEMENT_FILE
              value: /vault/secrets/credentials
          podAnnotations:
            vault.hashicorp.com/agent-inject: "true"
            vault.hashicorp.com/agent-init-first: "true"
            vault.hashicorp.com/agent-inject-secret-credentials: "database/creds/tsb-elastic-role"
            vault.hashicorp.com/agent-inject-template-credentials: |
              {{- with secret "database/creds/tsb-elastic-role" -}}
              user={{ .Data.username }}
              password={{ .Data.password }}
              trustStorePass=tetrate
              {{- end -}}
            vault.hashicorp.com/role: "es"
```

### 控制平面

控制平面也需要连接到 Elasticsearch 的凭据。你需要将 Vault 注入器的 pod 注释添加到控制平面中的 OAP 组件中。以下是带有所需更改的 YAML 片段。

```yaml
spec:
  components:
    oap:
      kubeSpec:
        deployment:
          env:
            - name: SW_ES_SECRETS_MANAGEMENT_FILE
              value: /vault/secrets/credentials
          podAnnotations:
            vault.hashicorp.com/agent-init-first: "true"
            vault.hashicorp.com/agent-inject: "true"
            vault.hashicorp.com/agent-inject-secret-credentials: database/creds/tsb-elastic-role
            vault.hashicorp.com/agent-inject-template-credentials: |
              {{- with secret "database/creds/tsb-elastic-role" -}}
              user={{ .Data.username }}
              password={{ .Data.password }}
              trustStorePass=tetrate
              {{- end -}}
            vault.hashicorp.com/role: es
```

{{<callout warning 注意>}}
在应用了 Vault 集成的注释后，你应该从管理平面和控制平面命名空间中删除 `elastic-credentials` 密钥。
{{</callout>}}

## 调试

你可以通过添加注释 `vault.hashicorp.com/log-level: trace` 来从 Vault-Injector 中添加更多调试信息。
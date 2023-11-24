---
title: PostgreSQL 凭据
description: 如何将 Vault Agent 注入器与 PostgreSQL 结合使用。
weight: 1
---

在开始之前，你必须具备以下条件：
- Vault 1.3.1 或更新版本
- Vault 注入器 0.3.0 或更新版本

## 设置 Vault

安装 Vault（不需要在 Kubernetes 集群中安装，但应该能够从 Kubernetes 集群内部访问）。Vault 注入器（agent-injector）必须安装到集群中，并配置以注入 sidecar。这可以通过自动完成 Helm 图表 `v0.5.0+` 来实现，该图表安装了 Vault `0.12+` 和 Vault 注入器 `0.3.0+`。下面的示例假设 Vault 安装在 `tsb` 命名空间中。

有关详细信息，请查看 [Vault 文档](https://www.vaultproject.io/docs/platform/k8s/injector/installation)。

```bash
helm install --name=vault --set='server.dev.enabled=true' ./vault-helm
```

## 为 PostgreSQL 设置数据库秘密引擎

在 Vault 中启用数据库秘密引擎。

```bash
vault secrets enable database
```

预期输出：
```text
Success! Enabled the database secrets engine at: database/
```

默认情况下，秘密引擎在与引擎同名的路径上启用。要在不同路径上启用秘密引擎，请使用 `-path` 参数。

使用适当的插件和连接信息配置 Vault。在 `connection_url` 参数中，将 `postgres.tsb.svc:5432/tsb` 替换为你的 PostgreSQL 集群的完整 `host:port/db_name`。只需更改 URL 中的小写 `username` 和 `password`，不要编辑在 URL 中的 `{{ }}`，它用作模板：

```bash
vault write database/config/tsb \
    plugin_name=postgresql-database-plugin \
    allowed_roles="pg-role" \
    connection_url="postgresql://{{username}}:{{password}}@postgres.tsb.svc:5432/tsb?sslmode=disable" \
    username="<postgres-username>" \
    password="<postgres-password>"
```

你可以使用 `read` 操作来查看配置：

```bash
vault read  database/config/tsb
# Key                                   Value
# ---                                   -----
# allowed_roles                         [pg-role]
# connection_details                    map[connection_url:postgresql://{{username}}:{{password}}@postgres.tsb.svc:5432/?sslmode=disable username:postgres]
# plugin_name                           postgresql-database-plugin
# root_credentials_rotate_statements    []
```

配置一个角色，将 Vault 中的名称映射到 Vault 可以执行以创建数据库凭据的模板化 SQL 语句。<br />
`max_ttl` 定义了新凭证的有效时间。<br />
`default_ttl` 定义了租约时间，Vault 注入器将续订租约，直到达到 `max_ttl`。

TTL 值必须与应用程序的数据库连接生命周期配对，以确保在 TTL 到期之前关闭它们。

运行以下命令，确保不要编辑 `{{ }}` 之间的参数，因为它们被 Vault 用作模板：

```bash
vault write database/roles/pg-role \
    db_name=tsb \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT ALL ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="12h" \
    max_ttl="24h"

Success! Data written to: database/roles/pg-role
```

再次使用 `read` 操作来验证设置：

```bash
vault read  database/roles/pg-role
# Key                      Value
# ---                      -----
# creation_statements      [CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';       GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";]
# db_name                  tsb
# default_ttl              24h
# max_ttl                  24h
# renew_statements         []
# revocation_statements    []
# rollback_statements      []
```

现在，通过使用角色名称从 `/creds` 终端点生成新凭据。这是 Vault 注入器将用于为你的 Kubernetes 应用程序获取凭据的机制：

```bash
vault read database/creds/pg-role
Key                Value
---                -----
lease_id           database/creds/pg-role/tUEs8eogkk9KL5erU5rLv7hD
lease_duration     24h
lease_renewable    true
password           A1a-1ZYMcUHKJIJH6rrc
username           v-token-pg-role-KQ4ze3GYi5He0D70tEmo-1587973449
```

## 设置 Kubernetes 秘密引擎

配置一个名为 "pg-auth" 的策略。这是一个非常不受限制的策略，但在生产环境中，你应该添加更多的限制。

```bash
vault policy write pg-auth - <<EOF
path "database/creds/*" {
    capabilities = ["read"]
}
EOF
Success! Uploaded policy: pg-auth
```

配置 Vault 以启用对 Kubernetes API 的访问。此示例假设你正在 Vault pod 中使用 `kubectl exec` 运行命令。如果不是这样，你将需要找到正确的 JWT 令牌、Kubernetes API URL（Vault 将用于连接到 Kubernetes 的 URL）以及 `vaultserver` 服务帐户的 CA 证书，如 [Vault 文档](https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes#define-a-kubernetes-service-account) 中所述。

```bash
vault auth enable kubernetes
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

将数据库策略附加到管理命名空间中的服务帐户（在这里是 `tsb` 命名空间）：

```bash
vault write auth/kubernetes/role/pg \
    bound

_service_account_names=* \
    bound_service_account_namespaces=tsb \
    policies=pg-auth \
    ttl=24h
```

要添加更多限制，为每个 `ServiceAccount` 创建一个角色。对于 PostgreSQL，你将需要为 `tsb-iam`、`tsb-spm` 和 `default` 服务帐户创建一个角色，因为 TSB API pod 使用 `default` 服务帐户运行：

```bash
vault write auth/kubernetes/role/pg \
    bound_service_account_names=default,tsb-spm,tsb-iam \
    bound_service_account_namespaces=tsb \
    policies=pg-auth \
    ttl=24h
```

## 将凭据注入到 Pod

要在管理平面中使用 Vault Agent 注入器与 PostgreSQL 结合使用，请向 `ManagementPlane` 自定义资源中的部署 pod 注释和环境变量中添加以下内容。

使用覆盖层来即时重新配置部署：

```yaml
spec:
  dataStore:
    postgres:
      connectionLifetime: 1h # 设置连接生存期
  components:
    apiServer:
      kubeSpec:
        deployment:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
              data:
                username: {{ .Data.username }}
                password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        overlays:
        - apiVersion: v1
          kind: Deployment
          name: tsb
          patches:
          - path: spec.template.spec.containers[name:tsb].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
          - path: spec.template.spec.initContainers[name:migration].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
    iamServer:
      kubeSpec:
        deployment:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
              data:
                username: {{ .Data.username }}
                password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        overlays:
        - apiVersion: v1
          kind: Deployment
          name: iam
          patches:
          - path: spec.template.spec.containers[name:iam].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
    spmServer:
      kubeSpec:
        deployment:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
              data:
                username: {{ .Data.username }}
                password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        job:
          podAnnotations:
            vault.hashicorp.com/agent-inject: 'true'
            vault.hashicorp.com/agent-init-first: 'true'
            vault.hashicorp.com/agent-inject-secret-config.yaml: 'database/creds/pg-role'
            vault.hashicorp.com/agent-pre-populate-only: "true"
            vault.hashicorp.com/agent-inject-template-config.yaml: |
              {{- with secret "database/creds/pg-role" -}}
                data:
                  username: {{ .Data.username }}
                  password: {{ .Data.password }}
              {{- end -}}
            vault.hashicorp.com/role: 'pg'
            vault.hashicorp.com/secret-volume-path: /etc/dbvault
        overlays:
        - apiVersion: v1
          kind: Deployment
          name: spm
          patches:
          - path: spec.template.spec.containers[name:spm].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
        - apiVersion: v1
          kind: CronJob
          name: spmsync
          patches:
          - path: spec.jobTemplate.spec.template.spec.containers[name:spmsync].args.[:/etc/db/config\.yaml]
            value: /etc/dbvault/config.yaml
```

## 调试

### 检查 PostgreSQL 中的角色

使用 PostgreSQL 命令行客户端 `psql` 来检查目标数据库 `tsb` 中的角色创建：

```bash
psql -h postgres -p 5432 -U tsb -d tsb
```

连接到数据库后，你可以使用 `\du` 命令列出数据库的当前角色：

```text
\du
 
                                                                                 List of roles
                     Role name                      |                         Attributes                         |                          Member of
----------------------------------------------------+------------------------------------------------------------+-------------------------------------------------------------
 rds_ad                                             | Cannot login                                               | {}
 rds_iam                                            | Cannot login                                               | {}
 rds_password                                       | Cannot login                                               | {}
 rds_replication                                    | Cannot login                                               | {}
 rds_superuser                                      | Cannot login                                               | {pg_monitor,pg_signal_backend,rds_replication,rds_password}
 rdsadmin                                           | Superuser, Create role, Create DB, Replication, Bypass RLS+| {}
                                                    | Password valid until infinity                              |
 rdsrepladmin                                       | No inheritance, Cannot login, Replication                  | {}
 tsb                                                | Create role, Create DB                                    +| {rds_superuser}
                                                    | Password valid until infinity                              |
                                                    |                                                            | {}
 v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | Password valid until 2020-05-20 12:08:23+00                | {}
 v-kubernet-pg-role-7uiTkWgsxphogXub0qpp-1589887199 | Password valid until 2020-05-20 11:20:04+00                | {}
...
```

你可以在这里看到角色 `tsb`，该角色用于在 Vault 中配置数据库，并且还有一些类似 `v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098` 的角色，这些角色对应于由 Vault 注入器 sidecar 动态创建的角色。

你还可以列出授予动态角色的访问权限。
以下是一个示例，涉及到角色 `v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098` 的权限示例：

```sql
SELECT grantee AS user, CONCAT(table_schema, '.', table_name) AS table,
   CASE
       WHEN COUNT(privilege_type) = 7 THEN 'ALL'
       ELSE ARRAY_TO_STRING(ARRAY_AGG(privilege_type), ', ')
   END AS grants
FROM information_schema.role_table_grants
WHERE grantee='v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098'
GROUP BY table_name, table_schema, grantee;
 
                       user                        |         table          | grants
----------------------------------------------------+------------------------+--------
v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | public.application     | ALL
v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | public.assignment      | ALL
v-kubernet-pg-role-5OUfsUQv3xAASWZkbECV-1589890098 | public.association     | ALL
...
```

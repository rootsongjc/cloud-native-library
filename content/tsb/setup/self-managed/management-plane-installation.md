---
title: 管理平面安装
description: 安装和设置 Tetrate Service Bridge 管理平面。
weight: 2
---

本页面将向你展示如何在生产环境中安装 Tetrate Service Bridge 管理平面。

在开始之前，请确保你已经：

- 检查了[要求](../../requirements-and-download)
- 检查了[TSB 管理平面组件](../../components#management-plane)
- 检查了[证书类型](../../certificate/certificate-setup)和[内部证书要求](../../certificate/certificate-requirements)

- 检查了[防火墙信息](../../firewall_information)

- 如果你正在升级以前的版本，请还要检查[PostgreSQL 备份和还原](../../../operations/postgresql)
- [下载](../../requirements-and-download#download)了 Tetrate Service Bridge CLI（`tctl`）
- [同步](../../requirements-and-download#sync-tetrate-service-bridge-images)了 Tetrate Service Bridge 镜像

## 管理平面 Operator

为了保持安装简单，但仍允许许多自定义配置选项，我们创建了一个管理平面 Operator。该 Operator 将在集群中运行，并根据 ManagementPlane 自定义资源中描述的内容引导管理平面的启动。它会监视更改并执行它们。为了帮助创建正确的自定义资源文档（CRD），我们已经添加了能力到我们的`tctl`客户端，用于创建基本清单，然后你可以根据你的要求进行修改。之后，你可以将清单直接应用于适当的集群，或在你的源控制操作的集群中使用。

{{<callout note "关于 Operator">}}
如果你想了解有关 Operator 的内部工作原理以及 Operator 模式的更多信息，请查看[Kubernetes 文档](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)。
{{</callout>}}

创建清单，以允许你从私有 Docker 注册表安装管理平面 Operator：

```bash
tctl install manifest management-plane-operator \
  --registry <registry-location> > managementplaneoperator.yaml
```

**OpenShift**

使用安装清单命令创建的`managementplaneoperator.yaml`文件可以通过使用 kubectl 客户端直接应用于适当的集群：

```bash
kubectl apply -f managementplaneoperator.yaml
```

应用清单后，你将在`tsb`命名空间中看到 Operator 正在运行：

```bash
kubectl get pod -n tsb
```

{{<callout note "RedHat 生态系统目录">}}}
TSB 已在 RedHat 生态系统目录上获得了认证并列出。可以按照以下说明或通过[此处](https://catalog.redhat.com/software/container-stacks/detail/63224dc0bc45b8cf6605f7e8)在 OpenShift 平台上安装 TSB。
{{</callout>}}

使用安装清单命令创建的`managementplaneoperator.yaml`文件可以通过使用`oc`客户端直接应用于适当的集群：

```bash
oc apply -f managementplaneoperator.yaml
```

应用清单后，你将在`tsb`命名空间中看到 Operator 正在运行：

```bash
oc get pod -n tsb
```

示例输出：

```text
NAME                                            READY   STATUS    RESTARTS   AGE
tsb-operator-management-plane-d4c86f5c8-b2zb5   1/1     Running   0          8s
```

## 配置机密

管理平面组件需要一些机密，用于内部和外部通信目的。以下是你需要创建的机密列表。

| 机密名称                 | 描述                                                         |
| ------------------------ | ------------------------------------------------------------ |
| `admin-credentials`      | TSB 将创建一个默认的管理员用户，用户名为：admin，这是该特殊帐户的密码的单向哈希。这些凭据保存在你的 IdP（身份提供者）之外，而其他任何凭据必须存储在你的 IdP 中。 |
| `tsb-certs`              | TLS 证书，类型为`kubernetes.io/tls`。必须具有`tls.key`和`tls.cert`值。TLS 证书可以是自签名的，也可以由公共 CA 颁发。 |
| `postgres-credentials`   | 包含：<br />&ensp;1. PostgreSQL 用户名和密码。<br />&ensp;2. 用于在 PostgreSQL 配置为呈现自签名证书时验证 PostgreSQL 连接的 CA 证书。仅当在 Postgres 设置中将`sslMode`设置为`verify-ca`或`verify-full`时，才会进行 TLS 验证。有关详细信息，请参见[PostgresSettings](../../../refs/install/managementplane/v1alpha1/spec#postgressettings)。 <br />&ensp;3. 如果 Postgres 配置了互通 TLS，则包含客户端证书和私钥。 |
| `elastic-credentials`    | Elasticsearch 用户名和密码。                                  |
| `es-certs`               | Elasticsearch 配置为呈现自签名证书时，用于验证 Elasticsearch 连接的 CA 证书。 |
| `ldap-credentials`       | 仅在使用 LDAP 作为身份提供者（IdP）时设置。包含 LDAP `binddn`和`bindpassword`。 |
| `custom-host-ca`         | 仅在使用 LDAP 作为 IdP 时设置。用于验证 LDAP 连接的 CA 证书，当 LDAP 配置为呈现自签名证书时。 |
| `iam-oidc-client-secret` | 仅在使用 OIDC 与任何 IdP 时设置。包含 OIDC 客户端密钥和设备客户端密钥。 |
| `azure-credentials` | 仅在使用 Azure AD 作为 IdP 时设置。用于连接到 Azure AD 进行团队和用户同步的客户端密钥。 |
| `xcp-central-cert` | XCP 中央 TLS 证书。请转到[内部证书要求](../../certificate/certificate-requirements)以获取更多详细信息。 |

### 使用 tctl 生成机密

{{<callout warning 注意>}}
自 1.7 以来，TSB 支持自动管理 TSB 管理平面 TLS 证书、内部证书和中间 Istio CA 证书。有关详细信息，请转到[自动证书管理](../../certificate/automated-certificate-management)。这意味着你不再需要创建`tsb-certs`和`xcp-central-cert`机密。以下示例将假定你正在使用自动证书管理。
{{</callout>}}

可以通过将它们作为命令行标志传递给`tctl`管理平面机密命令，以正确的格式生成这些机密。

**OIDC 作为 IdP**

以下命令将生成包含 Elasticsearch、Postgres、OIDC 和管理员凭据以及 TSB TLS 证书的`managementplane-secrets.yaml`：

```bash
tctl install manifest management-plane-secrets \
    --elastic-password <elastic-password> \
    --elastic-username <elastic-username> \
    --oidc-client-secret "<oidc-client-secret>" \
    --postgres-password <postgres-password> \
    --postgres-username <postgres-username> \
    --tsb-admin-password <tsb-admin-password> > managementplane-secrets.yaml
```

**LDAP 作为 IdP**

以下命令将生成包含 Elasticsearch、Postgres、LDAP 和管理员凭据以及 TSB TLS 证书的`managementplane-secrets.yaml`：

```bash
tctl install manifest management-plane-secrets \
    --elastic-password <elastic-password> \
    --elastic-username <elastic-username> \
    --ldap-bind-dn <ldap-bind-dn> \
    --ldap-bind-password <ldap-bind-password> \
    --postgres-password <postgres-password> \
    --postgres-username <postgres-username> \
    --tsb-admin-password <tsb-admin-password> > managementplane-secrets.yaml
```

查看[CLI 参考](../../../reference/cli/reference/install#tctl-install-manifest-management-plane-secrets)文档以获取所有可用选项，例如为`Elasticsearch`、`PostgreSQL`和`LDAP`提供 CA 证书。你还可以通过运行以下帮助命令，从`tctl`中检查绑定的解释：

```bash
tctl install manifest management-plane-secrets --help
```

### 应用机密

一旦你创建了机密清单，就可以将其添加到源代码控制或应用于你的集群。

{{<callout warning "Vault 注入">}}
如果你正在为某些组件使用`Vault`注入，请在将其应用到集群之前，从你创建的清单中删除适用的机密。
{{</callout>}}

**OpenShift**

```bash
kubectl apply -f managementplane-secrets.yaml
```

在应用它之前，请记住，你必须允许不同管理平面组件的服务帐户访问你的 OpenShift 授权策略。

```bash
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-iam
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-oap
```

现在可以应用它：

```bash
oc apply -f managementplane-secrets.yaml
```

注意：TSB 将每小时自动执行此操作，因此此命令只需在初始安装后运行一次。

### 验证安装

为验证你的安装成功，请使用管理员用户登录。尝试连接到 TSB UI 或使用`tctl` CLI 工具登录。

TSB UI 可通过以下命令返回的外部 IP 的端口 8443 访问：

**标准**

```bash
kubectl get svc -n tsb envoy
```

**OpenShift**

```bash
oc get svc -n tsb envoy
```

要将`tctl`的默认配置文件设置为指向你的新 TSB 集群，请执行以下操作：

**标准**

```bash
tctl config clusters set default --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
```
**AWS**

```bash
tctl config clusters set default --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8443
```

现在，你可以使用`tctl`登录，并提供组织名称和管理员帐户凭据。租户字段是可选的，可以在稍后配置，当添加租户到平台时。

```bash{outputLines: 2-5}
tctl login
Organization: tetrate
Tenant:
Username: admin
Password: *****
Login Successful!
```

查看[使用 tctl 连接到 TSB](../../tctl_connect)以获取有关如何配置 tctl 的更多详细信息。
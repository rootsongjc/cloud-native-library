---
title: 将 LDAP 配置为身份提供者
weight: 2
---

本文描述了如何配置 Tetrate Service Bridge（TSB）的 LDAP 集成。在 TSB 中，LDAP 集成允许你将 LDAP 用作用户登录 TSB 的身份提供者，并自动将用户和组从 LDAP 同步到 TSB。

本文假定你已经具备配置 LDAP 服务以及如何使用它进行身份验证的工作知识。

## 配置

LDAP 可以通过`ManagementPlane` CR 或 Helm 值进行配置。以下是一个使用 LDAP 作为 TSB 身份提供者的自定义资源 YAML 的示例。你需要编辑`ManagementPlane` CR 或 Helm 值，并配置相关部分。请参阅[`LDAPSettings`](../../../refs/install/managementplane/v1alpha1/spec#ldapsettings)了解更多详细信息。

以下各节将更详细地解释 YAML 文件的每个部分的含义。

```yaml
spec:
  hub: <registry-location>
  organization: <organization-name>
  ...
  identityProvider:
    ldap:
      host: <ldap-hostname-or-ip>
      port: <ldap-port>
      search:
        baseDN: dc=tetrate,dc=io
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember
```

## 身份提供者配置

使用 LDAP 作为身份提供者有两种方法：

- 使用直接绑定身份验证
- 使用基于搜索的身份验证

使用直接绑定身份验证是首选的，因为性能更好，但它要求整个 LDAP 树中的用户 Distinguished Names（"DN"s）是统一的。如果情况不是这样，可以配置更灵活的基于搜索的身份验证，以根据预先配置的查询对用户进行身份验证。

这些方法不是互斥的。如果都配置了，将首先尝试直接绑定身份验证，如果无法验证用户，TSB 将回退到使用基于搜索的身份验证。

### 直接绑定身份验证

在 LDAP 中，身份验证是通过执行与 DN 的绑定操作来完成的。DN 预期是一个已配置密码的用户记录。绑定操作尝试将给定的 DN 和密码与现有记录匹配。如果绑定操作成功，则身份验证成功。

然而，`DN`s 通常以以下形式出现，例如`uid=nacx,ou=People,dc=tetrate,dc=io`。这种格式对于常规登录来说不太方便，因为不应该要求用户在登录表单中键入完整的 DN。直接绑定身份验证允许你配置一个用于匹配登录用户的模式，并将其用作 DN。

以下示例配置了直接绑定身份验证模式：

```yaml
iam:
  matchdn: 'uid=%s,ou=People,dc=tetrate,dc=io'
```

在此示例中，登录时，模式中的`%s`将被提供的登录用户替换，生成的 DN 将用于绑定身份验证。

### 基于搜索的身份验证

如前所述，如果所有现有用户都可以与相同的 DN 模式匹配，直接绑定身份验证效果很好。然而，在某些情况下，用户可能会创建在 LDAP 树的不同部分（例如，每个用户可以在组织内特定部门的组内创建），这样就不可能有一个单一的模式来匹配所有用户。

在这种情况下，你可以在 LDAP 树上执行搜索，查找与给定用户名匹配的记录，然后尝试使用记录的 DN 进行绑定身份验证。

为了执行搜索，必须建立到 LDAP 服务器的连接。如果服务器未配置为匿名访问，可能需要凭据。有关更多详细信息，请参阅“凭据和证书”部分。

以下示例显示了如何配置基于搜索的身份验证：

```yaml
search:
  baseDN: dc=tetrate,dc=io
iam:
  matchfilter: '(&(objectClass=person)(uid=%s))'
```

在此示例中，配置了一个搜索，以查找从`dc=tetrate,dc=io`开始的树（`iam.matchFilter`使用在`search.baseDN`中定义的查询）。将尝试匹配所有类型为`person`并且具有`uid`属性等于给定用户名的记录。与直接绑定身份验证类似，搜索模式期望有一个`%s`占位符，该占位符将由给定的用户名替换。

### 结合直接和搜索身份验证方法

可以结合两种身份验证方法，以配置更灵活的身份验证配置。当同时配置了这两种方法时，直接绑定身份验证将具有优先权，因为它不需要遍历 LDAP 树，因此更有效率。

同时使用两种身份验证策略的示例可能如下所示：

```yaml
iam:
  matchdn: 'uid=%s,ou=People,dc=tetrate,dc=io'
  matchfilter: '(&(objectClass=person)(uid=%s))'
```

### 使用 Microsoft Active Directory

Microsoft Active Directory 以不同的方式实现了 LDAP 绑定身份验证。它不使用 LDAP 绑定操作的完整 DN，而是使用用户（应该是形式为：`user@domain`）。

由于这是在登录表单中可能配置的用户名，因此直接身份验证可以简单地配置如下：

```yaml
iam:
  matchdn: '%s'
```

如果直接身份验证无法满足所有身份验证需求，可以使用以下筛选器配置 Active Directory 中的基于搜索的身份验证，该筛选器匹配标准的 AD 用户帐户标识方式：

```yaml
iam:
  matchfilter: '(&(objectClass=user)(samAccountName

=%s))'
```

## 凭据和证书

某些操作需要对 LDAP 服务器运行特权查询，例如获取整个组和用户列表，或使用搜索对用户进行身份验证。在这些情况下，如果需要凭据，则必须在 Kubernetes Secret 中进行配置。

你可以使用 `tctl install manifest management-plane-secrets` 命令创建所需的凭据和证书，以连接到 LDAP 服务器。

```bash
tctl install manifest management-plane-secrets \
    …
    --ldap-bind-dn <ldap-bind-dn> \
    --ldap-bind-password <ldap-bind-password> \
    --ldap-ca-certificate "$(cat ldap-ca.cert)" \
    --tsb-admin-password <tsb-admin-password> \
    --tsb-server-certificate "$(cat foo.cert)" \
    --tsb-server-key "$(cat foo.key)" > managementplane-secrets.yaml
```

如果无法使用上述命令并需要手动执行此操作，请按以下方式创建 `ldap-credentials` 密钥：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ldap-credentials
  namespace: tsb
data:
  binddn: 'base64-encoded full DN of the user to use to authenticate'
  bindpassword: 'base64-encoded password'
```

还需要创建 `custom-host-ca` 密钥，如果你的 LDAP 配置为使用自签名证书。

```bash
kubectl create secret generic custom-host-ca \
    --from-file=ca-certificates.crt=<path to custom CA file> \
    --namespace tsb
```

## 用户和组同步

用户和组的同步是通过运行上述 LDAP 配置中的同步查询来完成的。以下示例显示了可用于从标准 LDAP 服务器获取用户和组的两个示例查询。

`membershipattribute` 用于将用户与他们所属的组进行匹配。对于每个找到的组，将读取此属性以提取组的成员信息。

请注意，这些查询高度依赖于 LDAP 树结构，每个人都必须更改它们以进行匹配。

```yaml
sync:
  usersfilter: '(objectClass=person)'
  groupsfilter: '(objectClass=groupOfUniqueNames)'
  membershipattribute: uniqueMember
```

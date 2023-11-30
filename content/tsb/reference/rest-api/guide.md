---
title: REST API 指南
weight: 1
description: 介绍如何使用我们的 REST API 与 TSB 进行通信的指南。
---

在本指南中，您将学习如何使用 TSB REST API 执行常见操作。本指南中的示例使用 `curl`，因为它是用于执行 HTTP 请求的常用命令，但任何可以执行 HTTP 请求的工具都可以使用。

## 身份验证

TSB 有两种主要的身份验证机制：基本身份验证和 JWT 令牌身份验证。

### 基本身份验证

[基本 HTTP 身份验证](https://tools.ietf.org/html/rfc7617) 通过在 HTTP `Authorization` 头中发送编码在头值中的凭据来完成。头的基本格式如下：

```text
Authorization: Basic base64(username:password)
```

例如：

```text
Authorization: Basic dGVzdDoxMjPCow==
```

### JWT 令牌身份验证

JWT 令牌身份验证是基于头的，并通过在 `x-tetrate-token` 头中设置 JWT 令牌来配置。例如：

```text
x-tetrate-token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

## HTTP 动词

TSB REST API 使用常见的 HTTP 动词来建模对不同 TSB 资源进行的所有操作：

- **GET** 请求用于获取资源列表或获取特定对象的详细信息。
- **POST** 请求用于创建新资源。
- **PUT** 请求用于修改现有资源。
- **DELETE** 请求用于删除资源及其子资源。

### 示例：常见资源 CRUD 操作

以下示例显示了如何使用 REST API 对 TSB 资源执行常见的 CRUD 操作：

#### 创建资源

在此示例中，您将在现有组织中创建一个租户。您可以通过向 TSB REST API 发送相应的 POST 请求并使用基本身份验证来执行此操作：

```bash
$ curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants \
    -X POST -d@- <<EOF
{
    "name": "mytenant",
    "tenant": {
      "displayName": "My tenant",
      "description": "Tenant created using the TSB REST API"
    }
}
EOF
```

输出：

```json
{"fqn":"organizations/myorg/tenants/mytenant","displayName":"My tenant","etag":"\"hhO8m7WN3LM=\"","description":"Tenant created using the TSB REST API"}
```

### 修改资源

通过在 PUT 请求中发送更新后的对象来修改资源。

要更新对象，您需要拥有它的最新副本。TSB 具有防止并发更新和避免相同对象的冲突版本的机制。为此，TSB 为每个对象分配一个 etag，并在每次对象更新时更新它。在 PUT 请求中，必须发送对象的最新 etag，以告诉 TSB 您正在修改对象的最新版本。

在此示例中，您将执行以下操作：

✓ 首先发送 GET 请求，以获取对象的最新版本（使用最新的 etag 更新）。<br />
✓ 在返回的 JSON 中进行本地修改。<br />
✓ 将修改后的 JSON 文档发送回以 PUT 请求。

```bash
curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants/mytenant \
    -X GET | jq .

```

输出：
```json
{
  "fqn": "organizations/myorg/tenants/mytenant",
  "displayName": "My tenant",
  "etag": "\"hhO8m7WN3LM=\"",
  "description": "Tenant created using the TSB REST API"
}
```

修改 JSON 文档并将其发送回。重要的是要保留 etag 字段：

```bash
curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants/mytenant \
    -X PUT -d@- <<EOF
{
  "fqn": "organizations/myorg/tenants/mytenant",
  "displayName": "My Modified tenant",
  "etag": "\"hhO8m7WN3LM=\"",
  "description": "Modified description"
}
EOF
```

输出：

```json
{"fqn":"organizations/myorg/tenants/mytenant","displayName":"My Modified tenant","etag":"\"BhsObrdJUWI=\"","description":"Modified description"}
```

### 删除资源

通过向资源的 URL 发送相应的 DELETE 请求来删除资源。如果将请求发送到父资源，则还将删除所有子资源。

```bash
curl -u username:password \
    https://tsbhost:8443/v2/organizations/myorg/tenants/mytenant \
    -X DELETE
```

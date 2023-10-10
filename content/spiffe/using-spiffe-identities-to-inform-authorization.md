---
weight: 9
title:  使用 SPIFFE 身份通知授权
linktitle: 8. 使用 SPIFFE 身份通知授权
date: '2022-10-07T00:00:00+08:00'
type: book
description: "本章解释了如何实施使用 SPIFFE 身份的授权策略。"
---

本章解释了如何实施使用 SPIFFE 身份的授权策略。

## 在 SPIFFE 的基础上建立授权

SPIFFE 专注于软件安全加密身份的发布和互操作性，但正如本书前面提到的，它并不直接解决这些身份的使用或消费问题。

SPIFFE 经常作为一个强大的授权系统的基石，而 SPIFFE ID 本身在这个故事中扮演着重要角色。在这一节中，我们将讨论使用 SPIFFE 来建立授权的选择。

## 认证与授权（AuthN Vs AuthZ）

一旦一个工作负载有了安全的加密身份，它就可以向其他服务证明其身份。向外部服务证明身份被称为认证（Authentication）。一旦通过认证，该服务就可以选择允许哪些行动。这个过程被称为授权（Authorization）。

在一些系统中，任何被认证的实体也被授权。因为 SPIFFE 会在服务启动时自动授予其身份，所以清楚地认识到并不是每一个能够验证自己的实体都应该被授权，这一点至关重要。

## 授权类型

有很多方法可以对授权进行建模。最简单的解决方案是在每个资源上附加一个授权身份的**允许列表（allowlist）**。然而，随着我们的探索，我们会注意到在处理生态系统的规模和复杂性时，允许列表的方法有几个限制。我们将研究两个更复杂的模型：基于角色的访问控制（RBAC）和基于属性的访问控制（ABAC）。

### 允许列表

在小型生态系统中，或者在刚刚开始使用 SPIFFE 和 SPIRE 时，有时最好保持简单。例如，如果你的生态系统中只有十几个身份，对每个资源（即服务、数据库）的访问可以通过维护一个有访问权限的身份列表来管理。

```bash
ghostunnel server --allow-uri spiffe://example.com/blog/web
```

在这里，ghostunnel 服务器仅根据客户的身份明确地授权访问。

这种模式的优势在于它很容易理解。只要你有数量有限的身份不改变，就很容易定义和更新资源的访问控制。然而，可扩展性会成为一个障碍。如果一个组织有成百上千的身份，维护允许名单很快就会变得无法管理。例如，每次增加一个新的服务，可能需要运维团队更新许多允许列表。

### 基于角色的访问控制（RBAC）

在基于角色的访问控制（RBAC）中，服务被分配给角色，然后根据角色来指定访问控制。然后，随着新服务的增加，只有相对较少的角色需要被编辑。

虽然有可能将一个服务的角色编码到它的 SPIFFE ID 中，但这通常是一种不好的做法，因为 SPIFFE ID 是静态的，而它被分配到的角色可能要改变。相反，最好是使用 SPIFFE ID 到角色的外部映射。

### 基于属性的访问控制（ABAC）

基于属性的访问控制（ABAC）是一个模型，授权决定是基于与服务相关的属性。结合 RBAC，ABAC 可以成为一个强大的工具来加强授权策略。例如，为了满足法律要求，可能有必要限制来自特定地区的服务对数据库的访问。区域信息可以是 ABAC 模型中的一个属性，用于授权并在 SPIFFE ID 方案中编码。

## 设计用于授权的 SPIFFE ID 方案

SPIFFE 规范没有规定或限制你可以或应该将哪些信息编码到 SPIFFE ID 中。你需要注意的唯一限制来自于最大长度的 SAN 扩展和你被允许使用的字符。

{{<callout note "忠告">}}

在将授权元数据编码成你的组织的 SPIFFE ID 格式时，要特别小心。下面的例子说明了如何做到这一点，因为我们并不想引入额外的授权概念。

{{</callout>}}

**SPIFFE 方案实例**

为了对 SPIFFE 身份子串做出授权决定，我们必须定义身份的每一部分意味着什么。你可以用按顺序编码信息的格式来设计你的方案。在这种情况下，第一部分可能代表一个地区，第二部分代表环境，以此类推。

下面是一个计划和身份的例子。

```
spiffe://trust.domain.org/<地区>/<dev,stage,prod>/<组织>/<工作负载名称>。
```

![图 8.1：一个组织的 SPIFFE ID 的组成部分和潜在含义。](../images/f8-1.jpg)

身份方案不仅可以采取一系列固定字段的形式，还可以采取更复杂的结构，这取决于一个组织的需求。我们可以看的一个常见的例子是跨不同协调系统的工作负载身份。例如，在 Kubernetes 和 OpenShift 中，工作负载的命名规则是不同的。下面的图示就是一个例子。你可能注意到，这些字段不仅指的是不同的属性和对象，而且 SPIFFE ID 的结构也取决于上下文。

消费者可以通过观察身份的前缀来区分方案的结构。例如，一个前缀为 `spiffe://trust.domain.org/Kubernetes/...` 的身份将根据下图的方案结构被解析为一个 Kubernetes 身份。

![图 8.2：另一个潜在的 SPIFFE ID 方案的说明。](../images/f8-2.jpg)

### 方案变更

更多时候，组织会发生变化，对身份方案的要求也会发生变化。这可能是由于组织结构的调整，甚至是技术栈的转变。可能很难预测你的环境在几年后会有多大的变化。因此，在设计 SPIFFE 身份识别方案时，关键是要考虑到未来可能发生的变化，以及这些变化将如何影响基于 SPIFFE 身份识别的其他系统。你应该考虑如何将后向和前向兼容性纳入该方案。正如我们之前已经提到的，在一个有序的方案中，你只需要在你的 SPIFFE ID 的末端添加新的实体；但是如果你需要在中间添加一些东西呢？

一种方法是用基于键值对的方案，另一种方法是我们都很熟悉的方法：版本管理！

**基于键值对的方案**

我们注意到，上面的方案设计都是有序的。方案的评估是通过查看身份的前缀来决定如何评估后面的后缀。然而，我们注意到，由于这种排序，很难轻易地在方案中增加新的字段。

键值对，就其性质而言，是无序的，这也是一种方法，可以轻松地将字段扩展到身份识别方案中，而不需要太多改变。例如，你可以使用带有已知分隔符的键值对，例如，身份内的列`：`字符。在这种情况下，上面的标识可能被编码为以下方式。

```
spiffe://trust.domain.org/environment:dev/region:us/organization:zero/name:turtle
```

因为身份的消费者将其处理成一组键值对，所以可以在不改变方案的基本结构的情况下增加更多的键。另外，SPIFFE 还有可能在将来支持将键值对纳 SVID。

像往常一样，应该考虑结构化和非结构化数据类型之间的权衡。

**版本管理**

这里可能的解决方案之一是将版本控制纳入方案。版本可以是你的方案中的第一个项目，也是最关键的部分。其余的系统在处理 SPIFFE ID 数据时需要遵循版本和编码实体之间的映射关系。

```
spiffe://trust.domain.org/v1/region/environment/organization/workload
v1 scheme:
0 = version
1 = region
2 = environment
3 = organization
4 = workload
spiffe://trust.domain.org/v2/region/datacenter/environment/organization/wor
kload
v2 scheme:
0 = version
1 = region
2 = datacenter
3 = environment
4 = organization
5 = workload
```

在 SPIFFE 中，一个工作负载可以有多个身份。然而，由你的工作负载来决定使用哪个身份。为了保持授权的简单性，每个工作负载最好先有一个身份，必要时再增加。

## 使用 HashiCorp Vault 的授权示例

让我们通过一个工作负载可能希望与之对话的服务的例子：Hashicorp Vault。我们将通过一个 RBAC 的例子和一个 ABAC 的例子，并涵盖一些使用 SPIFFE/SPIRE 执行授权时的问题和注意事项。

Vault 是一个**秘密存储器（secret store）**：管理员可以用它来安全地存储秘密，如密码、API 密钥和服务可能需要的私人密钥。由于许多组织仍然需要安全地存储秘密，即使在使用 SPIFFE 提供安全身份之后，使用 SPIFFE 来访问 Vault 是一个常见的请求。

```
spiffe://example.org/<区域>/<dev,stage,prod>/<组织>/<工作负载名称>。
```

### 为 SPIFFE 身份配置 Vault

在处理客户请求时，Vault 同时处理身份的认证和授权任务。像许多其他处理资源（在这里是指秘密）管理的应用程序一样，它有一个可插入各种认证和授权机制的接口。

在 Vault 中，这是通过 [TLS 证书认证方法](https://www.vaultproject.io/api/auth/cert)或 [JWT/OIDC 认证方法](https://www.vaultproject.io/api-docs/auth/jwt)，可以配置为识别和验证从 SPIFFE 生成的 JWT 和 X509-SVID。为了使 Vault 能够使用 SPIFFE 身份来使用，信任包需要配置这些可插拔的接口，以便它能够验证 SVID。

这就解决了认证问题，但我们仍然需要配置它来执行授权。要做到这一点，需要为 Vault 制定一套授权规则，以决定哪些身份可以访问秘密。

**一个 SPIFFE RBAC 的例子**

在下面的例子中，我们将假设我们使用的是 X509-SVID。Vault 允许创建规则，它可以表达哪些身份可以访问哪些秘密。这通常包括创建一组访问权限，并创建一个将其与访问绑定的规则。

例如，一个简单的 RBAC 策略：

```json
{
 "display_name": "medical-access-role",
 "allowed_common_names":
   ["spiffe://example.org/eu-de/prod/medical/data-proc-1",
    "spiffe://example.org/eu-de/prod/medical/data-proc-2"
],
 "token_policies": "medical-use",
}
```

这编码了一条规则，说明如果身份为 `spiffe://example.org/eu-de/prod/medical/data-proc-1`，或 `spiffe://example.org/eu-de/prod/medical/data-proc-2` 的客户能够获得一组权限（`medical-use`），它将授予医疗数据的访问权。

在这种情况下，我们已经授予这两个身份对秘密的访问权。Vault 负责将两个不同的 SPIFFE ID 映射到相同的访问控制策略中，这使得这成为 RBAC 而不是 allowlist。

**一个 SPIFFE ABAC 的例子**

在某些情况下，基于属性而不是基于角色来设计授权策略是比较容易的。通常情况下，当有多个不同的属性集可以单独与策略相匹配时，就需要这样做，而要创建足够多的独特角色来匹配每种情况是很有挑战性的。

根据上述例子，我们可以创建一个策略，授权具有某个 SPIFFE ID 前缀的工作负载。

```json
{ ...
 "display_name": "medical-access-role",
 "allowed_common_names":
   ["spiffe://example.org/eu/prod/medical/batch-job*"],
 "token_policies": "medical-use",
}
```

该策略规定，所有前缀为 `spiffe://example.org/eu/prod/medical/batch-job` 的工作负载将被授权访问该秘密。这可能很有用，因为批处理工作是短暂的，可能会被随机分配一个后缀。

另一个例子是一个有以下内容的策略：

```json
{ ...
 "display_name": "medical-access-role",
 "allowed_common_names":
   ["spiffe://example.org/eu-*/prod/medical/data-proc"],
 "token_policies": "medical-use",
}
```

该政策的预期效果是说明只有任何欧盟数据中心的 `data-proc` 工作负载可以访问医疗秘密。因此，如果在欧盟的一个新数据中心启动一个新的工作负载，任何 `data-proc` 工作负载将被授权访问医疗秘密。

### Open Policy Agent

开放策略代理（OPA）是云原生计算基金会（CNCF）的一个项目，执行高级授权。它使用一种名为 Rego 的特定领域编程语言，有效地评估传入请求的属性，并确定它应该被允许访问哪些资源。有了 Rego，就可以设计详细的授权策略和规则，包括 ABAC 和 RBAC。它还可以考虑到与 SPIFFE 无关的连接属性，例如传入请求的用户 ID。Rego 策略存储在文本文件中，因此它们可以通过持续集成系统集中维护和部署，甚至可以进行单元测试。

这里有一个例子，它编码了对某个数据库服务的访问，该服务应该只被某个 SPIFFE ID 所允许。

```json
# 允许后端服务访问数据库服务
allow {
  http_request.path == "/good/db"
  http_request.method == "GET"
  svc_spiffe_id == "spiffe://domain.test/eu-du/backend-server"
}
```

如果需要实施更详细的授权策略，那么 OPA 是一个不错的选择。Envoy 代理同时集成了 SPIRE 和 OPA，因此可以在不改变服务代码的情况下立即开始使用。要阅读更多关于使用 OPA 进行授权的细节，请查阅 OPA 文档。

## 总结

授权本身就是一个巨大而复杂的话题，远远超出了本书的范围。然而，就像生态系统中与身份交互的许多其他方面一样，了解身份与授权（以及更广泛的策略）的关系是非常有用的。

在本章中，我们介绍了使用 SPIFFE 身份认证的几种思考方式，以及与身份认证有关的设计考虑。这将有助于更好地了解你的身份解决方案的设计，以迎合你的组织的授权和策略需求。

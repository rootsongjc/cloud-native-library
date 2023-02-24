---
title: "基于角色的访问控制：五种常见的授权模型"
date: 2023-02-24T15:20:00+08:00
draft: false
authors: ["Omri Gazitt"]
summary: "本文描述了五种访问控制模式以及 Topaz 开源项目或 Aserto 授权服务等授权平台如何帮助你实施他们。"
tags: ["RBAC","安全","权限"]
categories: ["安全"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://thenewstack.io/role-based-access-control-five-common-authorization-patterns/
---

我们从最简单的基于 IDP 的 RBAC 开始，最终将基于组的 RBAC 与细粒度的权限和细粒度的资源相结合。

授权很复杂，因为每个应用程序都必须发明自己的授权模型。但是，有一些陈旧的路径可以作为大多数应用程序的良好起点。这篇文章将描述这些模式以及 [Topaz](https://topaz.sh/) 开源项目或 [Aserto](https://www.aserto.com/) 授权服务等授权平台如何帮助你实施他们。

## 角色作为用户属性

最简单的授权模式将一组角色建模为用户的属性。这些角色可以在身份提供者 (IDP) 中配置，并且通常作为范围嵌入到 IDP 生成的访问令牌中。

一些应用程序完全基于嵌入在访问令牌中的角色（或离散权限）进行授权。但这有一些[缺点](https://www.aserto.com/blog/oauth2-scopes-are-not-permissions)：

- **角色/权限/范围爆炸**：角色/权限越多，访问令牌中需要嵌入的范围就越多，从而导致大小问题。
- **IDP 和应用程序之间的耦合**：每当向应用程序添加新权限时，也必须修改访问令牌中生成其他范围的代码。这通常由有权访问 IDP 的安全/身份和访问团队完成，并且它引入了工作流程的复杂性。
- **一旦发布**，访问令牌就很难失效。只要访问令牌有效，经过身份验证的用户就拥有权限，即使他们的角色在令牌颁发后发生了变化。这反过来又会导致安全漏洞。

在这种情况下，使用 Topaz 等授权服务具有以下优势：

- 添加了一个明确的授权系统，让应用程序实时检查用户是否仍然拥有该角色或权限。
- 授权代码可以从应用程序中提取并表示为策略。这使得在整个应用程序中更容易推理授权逻辑。
- 每个 API 可以有不同的授权策略，其中包含授权操作的逻辑。一个示例策略可以是“如果用户具有‘管理员’或‘编辑者’角色，或者‘创建’权限，则允许该操作。”
- 任何角色更改（或用户全局“禁用”标志的值）都可以近乎实时地传输到授权系统。这解决了与盲目信任访问令牌中嵌入的范围相关的安全问题。
- 角色到权限的映射可以在授权系统中完成。因此，IDP 只需要知道用户到角色的映射，而不需要知道权限。这有助于将应用程序与 IDP 分离。

## 基于组的 RBAC

下一个模式依赖组（和组层次结构）作为组织用户。

通常通过使用户成为组的成员来分配这些角色。组成员身份意味着用户已被授予角色。组可以组织成层次结构。例如，“auditor”组可以包括“internal-auditors”和“external-auditors”。这两个组又可以包括特定用户。

这本质上是 LDAP 和 Active Directory 所围绕的模型。因此，大多数授权系统都支持将组作为其模型的核心部分。

例如，Topaz 和 Aserto 有一个内置的“组”对象类型。组对象类型具有“成员”关系类型，其目标可以是任何主体（用户或组）。此模型允许一个组包含在其他组中。检查组成员资格是传递性的：当使用用户和组实例调用 Topaz 的 check_relation 内置函数时，它将遍历组层次结构并直接或传递地返回 true，如果用户是组的成员。

以下策略（用 Open Policy Agent 的 [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) 语言编写）使用 Topaz 的内置 check_relation 来评估用户是否是一个组并允许行动：

```python
allowed {
  ds.check_relation({
    "subject": { "id": input.user.id },
    "relation": { "object_type": "group", "name": "member" },
    "object": {
      "type": "group",
      "key": input.resource.key 
    }
  })
}
```

由于可以通过多个角色授予权限，因此策略可能需要检查每个相应组的组成员资格。例如，如果用户是任何 Viewers、Editors 或 Administrators 组的成员，则可以授予 Can View 权限。这将通过以下策略实现：

```python
groups := { "viewer", "editor", "admin" }
allowed {
  ds.check_relation({
    "subject": { "id": input.user.id },
    "relation": { "object_type": "group", "name": "member" },
    "object": { "type": "group", "key": groups[_] }
  })
}
```

但这可能会变得复杂，并且可以说它只是将复杂性从应用程序逻辑转移到了策略上。下一个模式旨在解决这个问题。

## 具有细粒度权限的基于组的 RBAC

RBAC 代表基于角色的访问控制。权限可以包含在多个角色中。在上面的示例中，可以查看权限可能包含在查看者、编辑者和管理员角色中。更具可扩展性的授权系统将定义一组离散的权限并将这些权限分配给角色。

授权系统通常将权限定义为一级的概念。策略可以检查用户是否具有权限，而不是检查用户是否是组的成员。

下面的 Aserto 清单文件就是这样做的。它定义了一个“系统”对象类型，其下有两种关系类型：“editor”和“viewer”。“editor”关系类型包括“viewer”关系类型的所有权限，加上 can-edit 权限。查看者关系类型包含一种权限：can-view。

```yaml
system:
  editor:
    union:
    - viewer
    permissions:
    - can-edit
 
  viewer:
    permissions:
    - can-view
```

如果用户（或组）具有“editor”角色，Topaz 内置的 check_permission 会在评估用户是否具有 can-view 权限时返回 true。这是因为“editor”角色可传递地包含“viewer 角色”，因此具有可以查看的权限。

## 专有域对象的细粒度的授权

到目前为止，我们一直在处理“全局”角色。许多应用程序希望将权限授予它们管理的一组对象。例如，Google Drive 等文件共享应用程序将“文件夹”和“文件”定义为对象类型。文件夹和文件都可以有一个父文件夹。这些对象中的每一个都有一组关系（“所有者”、“编辑者”、“评论者”和“查看者”），并且“所有者”可以将这些角色授予用户和组。因此，可以将这些权限分配给离散的文件夹和文件，而不是对每个文件和文件夹具有编辑权限的全局“编辑器”角色。

[Google 的 Zanzibar](https://research.google/pubs/pub48190/) 是支持 Google 文档和许多其他 Google 应用程序的授权系统，它实现了这个模型。Zanzibar 启发了许多授权系统，包括 Airbnb 的 Himeji、Carta 的 AuthZ 和几个开源实现，包括 Topaz。

使用 Topaz，你可以定义特定领域的对象类型和关系类型。可以为每种关系类型定义权限（和/或其他关系类型的联合）。可以在[此处](https://github.com/aserto-dev/topaz-samples/blob/main/gdrive/model/manifest.yaml)找到支持此模型的清单的完整示例。

纯粹以评估主体（用户和组）和客体（例如文件夹和文件）之间的关系（例如“viewer”、“editor”）的形式建立的授权模型可以用非常简单的策略来表达：

```python
allowed {
  ds.check_permission({
    "subject": { "id": input.user.id },
    "permission": { "name": input.policy.path },
    "object": {
      "type": input.resource.type,
      "key": input.resource.key 
    }
  })
}
```

## 结合基于组的 RBAC 和 FGA

大多数现实世界的应用程序都实现了基于组的 RBAC 和细粒度授权的某种组合。通常，授权涉及检查全局角色（例如，“editor”），然后检查用户是否有权访问特定资源（例如，列表）。用户需要满足这两个条件才能编辑此列表中的项目。

另一个例子是“super-admin”，一个可以做任何事情的角色。访问检查包括允许用户通过关系访问特定对象的逻辑，以及允许访问具有这些提升角色的用户的逻辑。

Topaz 还支持这些场景，因为它建立在策略和基于关系的访问控制的组合之上。为了扩展前面的示例，我们可以在策略中添加另一个“允许”子句。如果用户已被授予对特定对象的特定权限，或者如果他们是“super-admin”，则此子句将允许操作：

```python
allowed {
   ds.check_permission({
     "subject": { "id": input.user.id },
     "permission": { "name": input.policy.path },
     "object": {
     "type": input.resource.type,
     "key": input.resource.key
      }
})
}

allowed {
     input.user.roles[_] == "super-admin"
}
```

## 总结

我们介绍了五种常见的授权模型，从最简单的基于 IDP 的 RBAC，到基于组的 RBAC 与细粒度权限和细粒度资源的结合。

Topaz 支持所有这些模型，同样重要的是，它可以通过改进授权策略轻松地从简单模型发展到更复杂的模型。

最终，每个成功的应用程序都需要一套深入的授权功能。在你的旅程中尽早采用像 Topaz 或 Aserto 这样的授权平台可以使你的应用程序面向未来，并且可以更轻松地根据你不断扩展的需求改进你的授权模型。

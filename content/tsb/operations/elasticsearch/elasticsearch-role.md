---
title: Elasticsearch 权限
weight: 1
description: Elasticsearch 所需权限的概述。
---

如果你的 Elasticsearch 访问受角色限制，你需要确保为 TSB 组件存在正确的角色。

## OAP

对于 OAP，必要的角色权限在下面的 JSON 中描述如下。

```json
{
  "cluster": ["manage_index_templates", "monitor"],
  "indices": [
    {
      "names": ["skywalking_*"],
      "privileges": ["manage", "read", "write"],
      "allow_restricted_indices": false
    }
  ],
  "applications": [],
  "run_as": [],
  "metadata": {},
  "transient_metadata": {
    "enabled": true
  }
}
```

你可以使用 cURL、`Kibana` 控制台或任何其他工具将此信息发布到 Elasticsearch 服务器以创建角色，然后你可以将该角色分配给将使用的 OAP 用户。
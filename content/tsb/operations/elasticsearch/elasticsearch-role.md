---
title: Elasticsearch privileges
menu-title: Privileges
description: Overview of required privileges in Elasticsearch.
---

If your Elasticsearch access is restricted by roles, you will need to make sure
the right roles exist for TSB components.

## OAP

For OAP, the necessary role permissions are described in the JSON below.

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

You can use cURL, `Kibana` console or any other tool to post this to the
Elasticsearch server to create the role, then you can assign the role to the
user OAP will be using.

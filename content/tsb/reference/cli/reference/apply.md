---
id: apply
title: tctl apply
description: Apply command
---
## tctl apply

Apply a configuration to a resource by filename or stdin

```
tctl apply [flags]
```

**Examples**

```
tctl apply -f config.yaml
```

**Options**

```
  -f, --file string          File or directory containing configuration to apply [required]
  -h, --help                 help for apply
  -o, --output-type string   Response output type: table, yaml, json
```

**Options inherited from parent commands**

```
  -c, --config string               Path to the config file to use. Can also be
                                    specified via TCTL_CONFIG env variable. This flag
                                    takes precedence over the env variable.
      --debug                       Print debug messages for all requests and responses
      --disable-tctl-version-warn   If set, disable the outdated tctl version warning. Can also be
                                    specified via TCTL_DISABLE_VERSION_WARN env variable.
  -p, --profile string              Use specific profile (default "default")
```


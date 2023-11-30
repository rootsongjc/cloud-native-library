---
title: tctl validate
description: Validate command
---

Offline validates a configuration from filename or stdin

```
tctl validate [flags]
```

**Examples**

```

tctl validate -f config.yaml

This syntactically validates the provided config and verifies the config of the defined selectors.

```

**Options**

```
  -f, --file string   File or directory containing configuration to validate [required]
  -h, --help          help for validate
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


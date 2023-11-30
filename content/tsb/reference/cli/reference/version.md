---
title: tctl version
description: Version command
---

Show the version of tctl and TSB

```
tctl version [flags]
```

**Options**

```
      --ascii        Display the ASCII art for the TSB release
  -h, --help         help for version
      --local-only   If true, shows client version only (no server required)
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


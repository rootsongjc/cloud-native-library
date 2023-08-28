---
id: collect
title: tctl collect
description: Collect command
---
## tctl collect

Collect the state of a Kubernetes cluster for debugging.

```
tctl collect [flags]
```

**Examples**

```

# Collect without any obfuscation or redaction
tctl collect

# Collect without archiving results (useful for local debugging)
tctl collect --disable-archive

# Collect and redact with user-provided regex
tctl collect --redact-regexes <regex-one>,<regex-two>

# Collect and redact with presets
tctl collect --redact-presets networking

```

**Options**

```
      --disable-archive           output files rather than tarball
  -h, --help                      help for collect
  -o, --output-directory string   the path to write the collected files under (default "tctl-[timestamp]")
      --redact-presets strings    Comma-separated list of redaction presets to use in collection data obfuscation.
                                  Available presets:
                                  - "networking": Obfuscate any data that matches IPv4 or IPv6 addresses. Any matches are replaced with SHA-256 hashes that are converted back to a valid IPv4 or IPv6.
      --redact-regexes strings    Obfuscate the data collected based on the list of provided regexes. Any matches are replaced with SHA-256 hashes of the matched string.
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


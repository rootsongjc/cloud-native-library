---
title: tctl login
description: Login command
---

Configures the credentials for the given user

**Synopsis**

Configures the credentials for the given user.

This command will exchange the given credentials for an access token that can be stored
in the configuration profile. If the credentials are not provided as arguments to the login
command, an interactive prompt will ask for all required information.

Organization and Tenant can also be configured with the following environment variables:
  - TCTL_LOGIN_ORG
  - TCTL_LOGIN_TENANT

Both password based and OpenID Connect based authentication are supported. Depending on the configured
authentication server there are several different authentication flags.

When password based authentication is configured, both --username and --password are required flags.
User credentials can also be configured with the following environment variables:
  - TCTL_LOGIN_USERNAME
  - TCTL_LOGIN_PASSWORD

When OpenID Connect based authentication is configured, users should authenticate with a browser
using an OpenID Connect Device Code. Device Code authentication is initiated with --use-device-code. Automation systems
may choose to use a trusted token exchange with --use-token-exchange and --access-token or --id-token. In both cases the username is inferred
from the OpenID Connect token subject claim and not the commandline flag.

The token exchange is done using the cluster settings defined in the current profile, and
the user information will be stored in a user with the name `<cluster name>-<username>`. This
user will be also set as the user for the current profile.


```
tctl login [flags]
```

**Options**

```
      --org string            Name of the organization
      --tenant string         Name of the tenant
      --username string       Username
      --password string       Password
      --use-device-code       Use OIDC device code login
      --use-token-exchange    Use OIDC token exchange
      --access-token string   Access Token
      --id-token string       ID Token
  -h, --help                  help for login
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


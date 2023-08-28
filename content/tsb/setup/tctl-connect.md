---
title: Connect to TSB with tctl
description: Configuring `tctl` to connect to TSB
weight: 7
---

In this page you'll learn to connect to TSB with the `tctl` CLI and some basics of using the CLI. 

Before you start: <br />
✓ [Install the TSB management plane](../setup/self_managed/management-plane-installation) (self-managed Only) <br />
✓ [Download](../setup/requirements-and-download#download) Tetrate Service Bridge CLI (`tctl`)<br />
✓ Get your TSB's `organization` name - you can find this logging in to the TSB UI or configured at installation time in the TSB `ManagementPlane` CR<br />

TSB provides a UI, but most examples in this site - and most scripting and automation - will use the `tctl` CLI. This document will cover how to get logged in so you can use the CLI, as well as steps to update your credentials.

## Overview

There are three ways to configure `tctl`: using `tctl login`, downloading the a credential bundle from the UI, or to manually configure it. Each method is described in detail in the rest of this document.

1. The preferred method is connecting to TSB with `tctl login`, using the `default` profile:

```bash{promptUser: alice}
tctl config clusters set default --bridge-address $TSB_ADDRESS
tctl login
Organization: tetrate
Tenant:
Username: admin
Password: *****
Login Successful!
# We're ready to go:
tctl get tenants
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

2. A second easy way to connect with `tctl` is to download the bundle from the TSB UI and `tctl config import` it:

```bash{promptUser: alice}
tctl config profiles import ~/Downloads/tctl-<your username>.config.yaml
tctl config profiles set-current <your username>-tsb
# We're ready to go:
tctl get tenants
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

3. And finally you can create your own `user`, `cluster`, and `profile` (with slightly different flags for LDAP vs OIDC) to log in:

```bash{promptUser: alice}
tctl config clusters set tsb-how-to-cluster --bridge-address $TSB_ADDRESS
# For OIDC
tctl config users set tsb-how-to-user --org $TCTL_LOGIN_ORG --token $TSB_BEARER_TOKEN --refresh-token $TSB_REFRESH_TOKEN
# Or for LDAP
# tctl config users set tsb-how-to-user --org $TCTL_LOGIN_ORG --username $TCTL_LOGIN_USERNAME --password $TCTL_LOGIN_PASSWORD
tctl config profiles set tsb-how-to --cluster tsb-how-to-cluster --username tsb-how-to-user
tctl config profiles set-current tsb-how-to
# We're ready to go:
tctl get tenants
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

If you logged in with a username and password, you should `tctl login` to exchange your password for a set of OIDC tokens. After this you can use `tctl` at will. For example to discover `tenants` in TSB, simply execute `tctl get tenants`.

## Log in with `tctl login`

The easiest way to get connected to TSB is to use the `tctl login` command, which will handle exchanging credentials for OIDC tokens for you, and ensure no plaintext passwords are persisted to disk.

To do this, first we need to configure `tctl` with the address of our TSB instance. It's easiest to use the `default` profile for this - if you don't want to use the `default` profile, skip ahead to the [Configure `tctl` Manually section](#configure-tctl-manually).

### Get TSB's Address
If your kubeconfig is pointed at the management plane cluster, you can get the address from the Kubernetes service:

```bash{promptUser: alice}
export TSB_ADDRESS=$(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
```

Many organizations will expose TSB's UI (and therefore API) via DNS; you should use that instead of the raw IP address.

### Configure the default profile

With TSB's address in hand, we'll configure `tctl` to connect to it:
```bash{promptUser: alice}
tctl config clusters set default --bridge-address $TSB_ADDRESS
```

### Log in with OIDC
To log in with OIDC, we can use the OIDC device code flow, which is built into `tctl`:
```bash{promptUser: alice}
tctl login --use-device-code
```

```bash{promptUser: alice}
Organization: tetrate
Tenant:
Code: GGBD-NJPR
Open browser page https://www.google.com/device and enter the code

Login Successful!
```

:::note OIDC in the browser
This will open up your browser for you to complete the OIDC login flow and generate tokens.
:::

### Log in with Username and Password 
Log in, providing your username and password:
```bash{promptUser: alice}
tctl login
```

```bash{promptUser: alice}
Organization: tetrate
Tenant:
Username: admin
Password: *****
Login Successful!
```

## Download `tctl` Config from TSB

`tctl` works with a config file to connect to a TSB instance, similar to kubeconfig for connecting to a Kubernetes API server. The easiest way to get connected with `tctl` is to download that config file from the TSB UI, following the instructions in the webpage. To get to those credentials, log in to the TSB UI in your browser, then in the top right corner click on your user name and under select `Actions` > `Show token information` > `Download tctl Config`. This will download a file named `tctl-<your username>.config.yaml`. You can then import this into `tctl`, saving it permanently:

```bash{promptUser: alice}
tctl config profiles import /path/to/tctl-<your username>.config.yaml
tctl config profiles set-current <your username>-tsb
```

:::note
`tctl` stores configuration in your file system's default configuration directory ([as determined by Golang](https://pkg.go.dev/os#UserConfigDir)). This would be `$HOME/.config/tetrate/tctl/tctl_config` on Linux, `$HOME/Library/Application\ Support/tetrate/tctl/tctl_config` on Darwin, or `%AppData%/tetrate/tctl/tctl_config` on Windows. This is where your password or tokens would persist. When you import a config file, `tctl` adds the credentials from that file to the existing credentials in its configuration directory. 
:::

## Configure `tctl` Manually

:::note TSB Organization Name
In the examples below, it is assumed that you have saved your organization name saved in the environment variable `$TCTL_LOGIN_ORG`. If you just completed the demo installation, the demo organization name is `tetrate`. You can execute the following to save the value in the environment variable: `export TCTL_LOGIN_ORG=tetrate`.
:::

To log in with `tctl`, you must first configure a *cluster* (`tctl config clusters`), then a *user* (`tctl config users`), then combine the two into a *profile*, which you  will be able to use to persist your settings, just like a kubeconfig profile (`tctl config profiles set-current ...`). With that *profile*, you can use the `tctl login` command to configure the credentials and persist to disk any tokens we need to continue to connect to TSB.

### Pick a name for your profile
`tctl` has a *default* profile just like `kubectl` which you can use for the commands below, or you can pick your own. For this how-to, create a profile named *`tsb-how-to`* (but any name works, including *default*).

### Configure the `tctl` Cluster
Both the UI and TSB's APIs are exposed on the same address and port. To configure `tctl`, you will need that address to get started.

#### Get TSB's Address
If your kubeconfig is pointed at the management plane cluster, you can get the address from the Kubernetes service:

```bash{promptUser: alice}
export TSB_ADDRESS=$(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
```

Many organizations will expose TSB's UI (and therefore API) via DNS; you should use that instead of the raw IP address.

#### Create a `tctl` Cluster
Once you have obtained the address (`$TSB_ADDRESS`) you can create a *cluster* in `tctl`'s config. Name the cluster `tsb-how-to-cluster`:

```bash{promptUser: alice}
tctl config clusters set tsb-how-to-cluster --bridge-address $TSB_ADDRESS
```

:::note `tctl` Object Names
You could use the same name for the cluster as for the profile itself (e.g. `tctl config clusters set tsb-how-to --bridge-address $TSB_ADDRESS`). This example uses a different name to make it easier to follow along.
:::

### Set `tctl`'s User

First you need to know the username you are logging in with. This will depend on exactly how TSB is installed: if you're using OIDC, this will be your corporate email; if you're using LDAP it'll be your usual LDAP login username; finally you can log in with TSB's default administrative account, if it's not disabled in your installation.

#### Login for OIDC Users

To log in to TSB with OIDC credentials, log in to the TSB UI in your browser, then in the top right corner click on your user name and under select `Actions` > `Show token information`. From that page, copy down the Bearer Token and Refresh Token, exporting them as `TSB_BEARER_TOKEN` and `TSB_REFRESH_TOKEN`:

```bash{promptUser: alice}
export TSB_BEARER_TOKEN=HHVMW2.qhf9jBL1fMCazBe1umanDr5sNEuFcKtClAUxeWA...redacted
export TSB_REFRESH_TOKEN=AJWXL6VmGUmvYfn43601RG.Bw+xr0IVQ43swidqAt1tHf...redacted
```
```bash{promptUser: alice}
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --token $TSB_BEARER_TOKEN \
  --refresh-token $TSB_REFRESH_TOKEN
```

#### Login for LDAP (username + password) Users
For LDAP logins, you need a username and password; you can configure these and environment variables, or pass them in via the CLI:

```bash{promptUser: alice}
export TCTL_LOGIN_USERNAME=demo-user@tetrate.io
export TCTL_LOGIN_PASSWORD=<your password>
```
```bash{promptUser: alice}
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --username $TCTL_LOGIN_USERNAME \
  --password $TCTL_LOGIN_PASSWORD
```

:::warning Username + Password Logins Write Password to disk
When you configure a user with a username and password, that password is written to disk. To ensure that credential is not saved to disk, you need to `tctl login` after setting up your cluster, user, and profile.
:::

#### Login for the Admin User

You can log in as the default administrative user with the same username and password scheme as an LDAP account:

```bash{promptUser: alice}
export TCTL_LOGIN_USERNAME=admin # this is hard-coded
export TCTL_LOGIN_PASSWORD=<your password> # you created this during management plane install
```
```bash{promptUser: alice}
tctl config users set tsb-how-to-user \
  --org $TCTL_LOGIN_ORG \
  --username $TCTL_LOGIN_USERNAME \
  --password $TCTL_LOGIN_PASSWORD
```

:::warning
It is recommend that you disable the admin user in all deployments of TSB. The primary use case for the admin user is for a platform owner to log in and configure their IdP so the rest of the organization can log in with OIDC or LDAP.

Finally, because this is a username and password login, you need to `tctl login` to exchange the password for a token for future access and to ensure the password is not saved to disk.
:::

### Create your `tctl` Profile

A *profile* ties a *cluster* and a *user* together so that they can be used to connect to a TSB instance. Connect the *cluster* and *user* you just created together into a *profile*:

```bash{promptUser: alice}
tctl config profiles set tsb-how-to --cluster tsb-how-to-cluster --username tsb-how-to-user
```

### Use the new Profile

Configure `tctl` to use the profile you just created to connect to TSB:

```bash{promptUser: alice}
tctl config profiles set-current tsb-how-to
```

At this point, you're good to go: `tctl` has TSB's location and your credentials - you can use it to interact with TSB!

### Verify the Config

As a sanity check, after finishing the following steps you can list your `tctl` profiles, and you should see something like:

```bash{promptUser: alice}
tctl config profiles list
```
```bash{promptUser: alice}
CURRENT   NAME         CLUSTER             ACCOUNT
          default      default             default
*         tsb-how-to   tsb-how-to-cluster  tsb-how-to-user
```

### Using `tctl` to find your Tenant

The final bit of setup you can do to make your life easier with `tctl` is to fill in your `tenant`, if you have not already done so.  Use `tctl` to ask TSB which tenants exist. For most users, there will be exactly one result returned - which is the tenant you want to be using. For users with multiple tenants, you'll need to talk with your platform team to determine which is the correct to use for you.

```bash{promptUser: alice}
tctl get tenants
```
```bash{promptUser: alice}
NAME          DISPLAY NAME    DESCRIPTION
tetrate       Tetrate         Default tenant
```

With your tenant in hand, you can save it to your user:

```bash{promptUser: alice}
tctl config users set tsb-how-to-user --tenant <your tenant>
```

### Log in with `tctl`

When you log in with username and password, both are persisted to disk. This is not desirable, as your password is stored in plaintext. To remove the password from `tctl`'s config file, you can use [`tctl login`](../reference/cli/reference/login), which will exchange your credentials for a set of OAuth tokens and write those to disk instead.

```bash{promptUser: alice}
tctl login
```

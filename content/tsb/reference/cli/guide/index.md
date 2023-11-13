---
slug: index
id: index
title: Getting Started
description: Getting started with Tetrate Service Bridge CLI.
---

Tetrate Service Bridge's command line interface (CLI) lets you interact with the
TSB API allowing you for easy manipulation of objects and configurations in a
programmatic, or interactive way. CLI works by submitting YAML representation of
TSB or Istio objects.

## Installation

TSB CLI is a single binary which is available for Linux, MacOS and Windows.

<Tabs
  defaultValue="Linux"
  values={[
    {label: 'Linux', value: 'Linux'},
    {label: 'MacOS', value: 'MacOS'},
    {label: 'Windows', value: 'Windows'},
  ]}>
  <TabItem value="Linux">

Use `curl` or `wget` to download the binary, grant permissions to execute and
place it somewhere in your `$PATH`.

<pre><code>
{`mkdir -p ~/.tctl/bin
curl -Lo ~/.tctl/bin/tctl https://binaries.dl.tetrate.io/public/raw/versions/linux-$(uname -m | sed s/x86_64/amd64/)-${vars.versionNumber}/tctl
chmod +x ~/.tctl/bin/tctl
export PATH=$PATH:~/.tctl/bin`}
</code></pre>

Or with `wget`:

<pre><code>
{`mkdir -p ~/.tctl/bin
wget -q -O ~/.tctl/bin/tctl https://binaries.dl.tetrate.io/public/raw/versions/linux-$(uname -m | sed s/x86_64/amd64/)-${vars.versionNumber}/tctl
chmod +x ~/.tctl/bin/tctl
export PATH=$PATH:~/.tctl/bin`}
</code></pre>

  </TabItem>
  <TabItem value="MacOS">

Use `curl` or `wget` to download the binary, grant permissions to execute and
place it somewhere in your `$PATH`.

<pre><code>
{`mkdir -p ~/.tctl/bin
curl -Lo ~/.tctl/bin/tctl https://binaries.dl.tetrate.io/public/raw/versions/darwin-$(uname -m | sed s/x86_64/amd64/)-${vars.versionNumber}/tctl
chmod +x ~/.tctl/bin/tctl
sudo xattr -r -d com.apple.quarantine ~/.tctl/bin/tctl
export PATH=$PATH:~/.tctl/bin`}
</code></pre>

Or with `wget`:

<pre><code>
{`mkdir -p ~/.tctl/bin
wget -q -O ~/.tctl/bin/tctl https://binaries.dl.tetrate.io/public/raw/versions/darwin-$(uname -m | sed s/x86_64/amd64/)-${vars.versionNumber}/tctl
chmod +x ~/.tctl/bin/tctl
sudo xattr -r -d com.apple.quarantine ~/.tctl/bin/tctl
export PATH=$PATH:~/.tctl/bin`}
</code></pre>

  </TabItem>
  <TabItem value="Windows">

Download the `tctl.exe` binary to a directory under `Program Files`. You might
need to run the following commands from an elevated PowerShell prompt.

<pre><code>
{`mkdir "%USERPROFILE%\tctl"
mkdir "%USERPROFILE%\tctl\bin"
Invoke-WebRequest -Uri https://binaries.dl.tetrate.io/public/raw/names/tctl/versions/windows-amd64-${vars.versionNumber}/tctl.exe -OutFile "%USERPROFILE%\\tctl\\bin\\tctl.exe"`}
</code></pre>

You will need to add the `%USERPROFILE%\tctl\bin` path to the system environment
variable `%PATH%`.

  </TabItem>
</Tabs>

## Configuration

CLI configuration supports multiple profiles for easily manage different
environments from the same CLI. A profile in the CLI is defined by a single pair
of cluster and credentials.

### Credentials

Credentials in the CLI are referred to as `user`. The full reference for the
`user` sub-command can be found in the
[CLI reference](../reference/config#tctl-config-users) page. An example for
creating an `admin-user` user is shown below.

```bash
tctl config users set admin-user --username admin --password 'MySuperSecret!' --org tetrate --tenant tenant1
```

Whenever the `admin-user` is used in a profile, the CLI will submit the `admin`
user and `MySuperSecret!` password, as well as the `tetrate` organization and
`tenant1` tenant.

:::note Special characters in passwords
Do be careful when you are using characters that may be considered special
characters in your terminal. For example, if you include a '$' (dollar mark) and
quote them using double quotes , it may be interpreted in an unexpected manner.

Since each terminal may behave ever so slightly differently, please always
consult your manual for the exact syntax to avoid these special characters from
being interpreted in an unexpected way. As a general rule, in most cases using
single quotes should be safe.

This caveat applies to almost everything that you type on a terminal, but
passwords have a higher risk as use of special characters is encouraged.
:::

### Clusters

Clusters in the CLI map to a given TSB API endpoint. The full reference for the
`clusters` sub-command can be found in the
[CLI reference](../reference/config#tctl-config-clusters) page. An example for
creating a `my-tsb` cluster is shown below.

```bash
tctl config clusters set my-tsb --bridge-address my.tsb.corp:8443
```

Whenever the `my-tsb` is used in a profile, the CLI will send the requests to
the `https://my.tsb.corp:8443/` endpoint.

### Profiles

A profile is a given combination of `cluster` and `username`. The result of that is
the CLI sending requests to the endpoint specified by the `cluster`,
authenticating with the `username` credentials. The full reference for the
`profiles` sub-command can be found in the
[CLI reference](../reference/config#tctl-config-profiles) page. An example for
creating a `demo-tsb` profile is shown below.

```bash
tctl config profiles set demo-tsb --cluster my-tsb --username admin-user
```

The CLI can have multiple `profiles` using different combinations of clusters
and users. One of the profiles will be used as default when the option
`--profile` is not specified. You can change the current profile at any time as
shown below.

```bash
tctl config profiles list
  CURRENT  NAME      CLUSTER      ACCOUNT
  *        default
           demo-tsb  my-tsb       admin-user

tctl config profiles set-current demo-tsb

tctl config profiles list
  CURRENT  NAME      CLUSTER      ACCOUNT
           default
  *        demo-tsb  my-tsb       admin-user
```

## Command completion

`tctl` provides completion for the `bash` shell, allowing for easy discovery of
commands and their flags. Provided you have `bash` completion enabled, you can
source the output of the [completion](../reference/completion) command to get
the auto completion of `tctl` commands for `bash` working.

```bash
source <(tctl completion bash)
```

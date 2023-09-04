---
title: Change The Administrator Password
description: Change the password for the TSB administrator.
---

This document describes how to change the password for the TSB administrator.

The TSB administrator is configured locally in every TSB instance and does not belong to the
corporate Identity Provider (IdP). This allows the superuser to be able to log into TSB in case of
issues connecting to the Identity Provider in order to do troubleshooting and platform fixes.

## Update the secret

Admin credentials are stored in the `admin-credentials` Kubernetes secret in the Management Plane
namespace (`tsb` by default). It is securely stored as a SHA-256 hash so it cannot be reversed, and it
can be modified by directly updating the secret with the SHA-256 for the desired password.

The following example shows how to generate an updated secret that can be later applied:

```bash
new_password="Tetrate1"
new_password_shasum=$(echo -n $new_password | shasum -a 256 | awk '{print $1}')
kubectl -n tsb create secret generic admin-credentials --from-literal=admin=$new_password_shasum --dry-run=client -o yaml
```

This will output the YAML for the secret with the updated password, and it can be applied normally with `kubectl`.

Once the secret has been updated, the `iam` deployment pods need to be restarted for changes to be loaded:

```bash
kubectl -n tsb rollout restart deployment/iam
```

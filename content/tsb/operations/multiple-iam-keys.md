---
title: Configure multiple IAM token validation keys
description: Configure multiple IAM token validation keys
---

This document describes how to configure the Management Plane IAM service to have multiple keys to validate
JWT tokens. This can be useful when rotating the IAM signing key while still allowing access for tokens issued with the old
key that has not yet expired.

The following example illustrates the process of migrating the main IAM signing key from using the key from the `tsb-certs`
certificate to use a custom signing key.

## Fetching the current signing key

First of all you need to retrieve the configuration for the token issuer with:

```bash
kubectl -n tsb get managementplane managementplane
```

And find the [token issuer](../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings) configuration.
In this example, the following issuer is configured:

```yaml
tokenIssuer:
  jwt:
    expiration: 3600s
    issuers:
    - name: https://demo.tetrate.io
      signingKey: tls.key
    refreshExpiration: 2592000s
    signingKeysSecret: tsb-certs
    tokenPruneInterval: 3600s
```

This indicates that the current signing key is the one in the `tls.key` entry in the `tsb-certs` secret. We can retrieve it and save it for later as follows:

```bash
kubectl get secret -n tsb tsb-certs -o jsonpath='{.data.tls\.key}' | base64 -d >/tmp/old-key.pem
```

## Generating a new secret for the signing keys

The next thing is to generate a new secret with the new IAM signing key. This can be done in many ways, but in this example you'll create a new RSA key.
Please refer to the [supported key algorithms list](../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings-issuer-algorithm)
for further details about the supported keys.

```bash
$ cat /opt/iam-key.pem

-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEA+KdhvSZBExMHlaWo7MdKA8Ku55iu/y4FwMPixitjs/DUgaQ5
1AVHyuWcV576qMi1pZwFGbx72sU+oMS4BHr8JNv5a1DwwCKdidD89aAWeL5gmCdB
1gh5qrIBohvQQ5clnQnl7PXYauDohy9U5sIWzrZ1222sweYHVhD7A1Hd7864faR4
103xP/kyvT3b2kBauAXiLQoqFT7Uk0eR/uiJmjkl8lBFt/s3ApChRytxjxiDZiGW
x6Hw9rfEcgzu0gvpJpntCHY9WrdSO1YyXbWJ2C/59OwRkhqO1UOsl7QlHrWGGGYD
9CiGPahYhSt1qq01Dk6ievJQGv16Sd2Rv+rbNwIDAQABAoIBAQCqfOGX9k2yDV8q
7P3o8y+9alPQObDrCBwrsmOfqopfCyY5iWeZBtHVvR84OKn25j8dwN8CaWimdI1f
X+IoOEb/4s+eFE4t/s3ze5alt1EREr9aM7iBTyhUsF5MTzO51D2W8f1zPpFXnsPw
RLS6z6MhspsWi5ljDRxEl7nz6cL5M3LujW/bQMk/uG8noA2mRCywGij/6tEzytR9
+h7y0A2QU36YF6yS/amOyP+3LgpycyV6LMercABgnPUse7iLDWGg+uxPBTts78oS
b1YGe20cSTDrfrDHkgYXuUKRiI7blH9+VDgLR4iZHYSdr+8cZ8zxCKKGzbW7UClP
hNZ+nb9xAoGBAP620Azi+OplI1nLUetPm1X0VfZeMKg8w3gsw4DxECiKF9y5PPje
7E8DgQLl99fRNKGJoNCbdC5c6cwZv0MIiC2qyhTsaNiGZt+kGx3KcVQtjBu0sIyA
YFmWYNFbIkcu3W7ugVrLk74u2BPN8YQMVse2sa9ODWE9ZL2A0mBIqUe5AoGBAPno
vKanUg5Djk3CJPjOaDmUr9RS9Jiou/EdCWKjHwER8nNSQU/f/YKC0h8CGdiUA1HD
Jj353Rn2bSkB2DO3S64jkOr5GmXZIf5G8GCMIBkRlGHZtZoOUlWYZyitv34wuf91
e/T+50mvt3KWdvvgiG3CUpCs5sagccKJGTJYp9JvAoGBALbl6IDIXjpZQ0gQEhOo
xv6ygyN0QPYdI7LgWcX100d42WeZ76k40XBvMK03Gn9y7prr63i/l25PM2ZmOotU
zgwUriTWGPcZkzcVbI84taXfStL+LSPGbukFbSIHkZaRlVk5k9LxiXYvxuJ5p+nM
vmeLzQz3O+5OGk9k+CtBIaSpAoGBALZBIIvdjL8wT3Cv/OyjA2my4QRUt2M5806l
YXnZArxyDUJDI7SP4z8yDvFkQ9sqHr2bN6GNPs03ZWa5nKYisAPAlmh24OSUFPFv
ZNDUgHgn1PIDpyhB95PLALiu9e+es5b1ZEBJQf4AMyZTS1Tn7Dc3t6UhI3CKBEze
VUzdUQ7rAoGBAJ9y76IWic7PIBbstNOq0ejsq3iMEoH/fn84lYwMDEzRLV3Y+HvQ
mu69O2h7ud88ozXJntC0VTv2nU1cKpiMHq3jZ0vxNmJomd7wKxwunKAZj8GJczhm
8T+O1c682fgu4YPysGJw35j/oGed0pEKXhBMMJh/X8HPmBcujHZYXDy0
-----END RSA PRIVATE KEY-----
```

Then you will generate a new secret that contains the new key and the OLD key as well:

```bash
kubectl -n tsb create secret generic iam-signing-keys \
    --from-file=new.key=/opt/iam-key.pem \
    --from-file=old.key=/tmp/old-key.pem
```

This would create a secret like the following one, containing the old and the new key:

```bash
kubectl -n tsb get secret iam-signing-keys -o yaml
apiVersion: v1
data:
  new.key: [...]
  old.key: [...]
kind: Secret
metadata:
  creationTimestamp: "2022-12-14T15:56:46Z"
  name: iam-signing-keys
  namespace: tsb
  resourceVersion: "3378979"
  uid: 54cea82b-4505-49bb-a12e-fe6f5fbee1de
type: Opaque
 ```

## Updating the Management Plane to use the new keys

Once the secret with all the IAM signing keys has been created, all that is needed is to update the `tokenIssuer` in the `ManagementPlane` CR or Helm values 
accordingly. In our example, it would be as follows:

```yaml
tokenIssuer:
  jwt:
    expiration: 3600s
    issuers:
    - name: https://newissuer.tetrate.io
      algorithm: RS256
      signingKey: new.key
    - name: https://demo.tetrate.io
      algorithm: RS256
      signingKey: old.key
    refreshExpiration: 2592000s
    signingKeysSecret: iam-signing-keys
    tokenPruneInterval: 3600s
```

The changes needed are:

* Update the `signingKeysSecret` to use the newly created secret containing the two keys.
* Declare two issuers, one for each key in the new secret. The **first issuer** in the list is the one that will be used to sign new JWT tokens,
  so make sure you put the new key first if you want it to be used to sign the new JWT tokens. The rest of the issuer's keys will be only used
  for token verification.

:::note
It is important that you choose **a different issuer** (it can be any string) for the new key and that you keep the old issuer for the old
key. Otherwise token verification will not work.
:::

Once the token issuer information has been updated in the `ManagementPlane`, new tokens will be issued with the new key, and old tokens will
still be accepted. Once all tokens have been migrated and the old key is not needed anymore, the old issuer can be removed from the issuers list
and the old key can be removed from the secret as well.

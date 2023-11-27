---
title: 配置多个 IAM 令牌验证密钥
description: 配置多个 IAM 令牌验证密钥。
weight: 8
---

本文描述如何配置管理平面 IAM 服务以具有多个密钥来验证 JWT 令牌。当轮换 IAM 签名密钥但仍允许访问使用旧密钥签发且尚未过期的令牌时，这将非常有用。

以下示例演示了从`tsb-certs`证书使用主 IAM 签名密钥迁移至使用自定义签名密钥的过程。

## 获取当前签名密钥

首先，你需要使用以下命令检索带有令牌签发者配置的配置：

```bash
kubectl -n tsb get managementplane managementplane
```

并找到[token 签发者](../../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings)配置。
在此示例中，配置如下所示：

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

这表示当前的签名密钥是`tsb-certs`秘密中的`tls.key`条目。我们可以检索它并保存以备将来使用：

```bash
kubectl get secret -n tsb tsb-certs -o jsonpath='{.data.tls\.key}' | base64 -d >/tmp/old-key.pem
```

## 生成新的签名密钥的新密钥

接下来要做的是生成一个新的秘密，其中包含新的 IAM 签名密钥。这可以通过多种方式完成，但在此示例中，你将创建一个新的 RSA 密钥。
有关支持的密钥的详细信息，请参阅[支持的密钥算法列表](../../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings-issuer-algorithm)。

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
YXnZArxyDUJDI7SP4z8yDvFkQ9sqHr2bN6GNPs03ZW

a5nKYisAPAlmh24OSUFPFv
ZNDUgHgn1PIDpyhB95PLALiu9e+es5b1ZEBJQf4AMyZTS1Tn7Dc3t6UhI3CKBEze
VUzdUQ7rAoGBAJ9y76IWic7PIBbstNOq0ejsq3iMEoH/fn84lYwMDEzRLV3Y+HvQ
mu69O2h7ud88ozXJntC0VTv2nU1cKpiMHq3jZ0vxNmJomd7wKxwunKAZj8GJczhm
8T+O1c682fgu4YPysGJw35j/oGed0pEKXhBMMJh/X8HPmBcujHZYXDy0
-----END RSA PRIVATE KEY-----
```

然后，你将生成一个包含新密钥和旧密钥的新秘密：

```bash
kubectl -n tsb create secret generic iam-signing-keys \
    --from-file=new.key=/opt/iam-key.pem \
    --from-file=old.key=/tmp/old-key.pem
```

这将创建一个包含旧密钥和新密钥的秘密，如下所示：

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

## 更新管理平面以使用新密钥

一旦创建了包含所有 IAM 签名密钥的秘密，只需要相应地更新`ManagementPlane` CR 或 Helm 值中的`tokenIssuer`即可。在我们的示例中，如下所示：

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

需要进行的更改包括：

* 更新`signingKeysSecret`以使用包含两个密钥的新创建的秘密。
* 声明两个签发者，一个用于新密钥中的每个密钥。列表中的**第一个签发者**将用于签署新的 JWT 令牌，因此如果要使用新密钥签署新的 JWT 令牌，请确保首先放置新密钥。其余签发者的密钥仅用于令牌验证。

{{<callout note 注意>}}
重要的是，你选择**不同的签发者**（可以是任何字符串）用于新密钥，同时保留旧密钥的旧签发者。否则，令牌验证将无法正常工作。
{{</callout>}}

一旦在`ManagementPlane`中更新了令牌签发者信息，将使用新密钥签发新令牌，而旧令牌仍将被接受。一旦所有令牌都已迁移且不再需要旧密钥，就可以从签发者列表中删除旧签发者，还可以从秘密中删除旧密钥。
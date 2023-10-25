---
weight: 5
title: "SPIFFE 信任域和 Bundle"
---

SPIFFE 标准提供了一个规范，用于在异构环境和组织中引导和发放可互操作的服务身份。它定义了一个称为"信任域"的概念，用于划分管理和/或安全边界。信任域隔离发放机构并区分身份命名空间，但也可以松散耦合以提供联合身份。

本文档描述了 SPIFFE 信任域的语义、表示方式以及它们如何耦合在一起的机制。

## 引言

SPIFFE 信任域表示 SPIFFE ID 有资格的基础，指示任何给定 SPIFFE ID 已经发放的领域或发放机构。它们由发放机构支持，负责管理其相应信任域中的 SPIFFE 身份发放。尽管信任域的名称由一个简单的人类可读字符串组成，但还必须表达由信任域的发放机构使用的密码密钥，以使其他人能够验证其发放的身份。这些密钥被表示为"SPIFFE Bundle"，与其所代表的信任域紧密相连。

本规范定义了 SPIFFE 信任域和 SPIFFE Bundle 的性质和语义。

## 信任域

SPIFFE 信任域是由一组密码密钥支持的身份命名空间。这些密钥共同为驻留在信任域中的所有身份提供了密码锚点。

信任域与支持它们的密钥之间存在一对多的关系。一个信任域可以由多个密钥和密钥类型来表示。例如，前者可以在根密钥轮换期间使用，而后者在使用多个 SVID 类型时避免多协议攻击是必要的。

需要注意的是，虽然可以在多个信任域之间共享密码密钥，但我们强烈建议每个授权密钥仅在一个信任域中使用。密钥的重复使用可能会降低信任域的隔离性（例如，在演练和生产之间），并引入额外的安全挑战（例如，需要为辅助发放机构实施名称约束系统）。

## SPIFFE Bundle (SPIFFE Bundle)

SPIFFE Bundle 是包含信任域的密码密钥的对象。Bundle 中的密钥被视为代表 Bundle 所代表的信任域的权威，并用于证明驻留在该信任域中的 SVIDs 的有效性。

SPIFFE Bundle 设计用于在 SPIFFE 控制平面实现内部和之间使用。然而，此规范不排除直接由工作负载消费的使用。

在存储或管理 SPIFFE Bundle 时，独立记录 Bundle 所代表的信任域的名称至关重要，通常通过使用`<trust_domain_name, bundle>`元组来实现。在验证 SVID 时，验证器必须选择与 SVID 所在的信任域对应的 Bundle，因此在大多数情况下需要维护此关系。

请注意，信任域 Bundle 的内容预计会随时间变化，因为它所包含的密钥进行轮换。通过发放包含新密钥的新 Bundle 并省略已撤销的密钥来添加和撤销密钥。SPIFFE 实现负责根据需要将 Bundle 内容更新分发给工作负载。确切的格式和通过哪种方法传递这些更新超出了本规范的范围。

## SPIFFE Bundle 格式

SPIFFE Bundle 被表示为 RFC 7517 兼容的 JWK 集合。选择 JWK 的原因有两个主要原因。首先，它提供了一种灵活的格式，用于表示各种类型的密码密钥（和 X.509 等文档），从而在定义新的 SVID 格式时提供了一定程度的未来证明。其次，它得到了广泛支持和部署，主要用于域间联合，这是 SPIFFE 项目的核心目标。

### JWK 集合

本节定义了 JWK 集合的参数。未在此处定义的参数可以根据实现者的需要包含，但是 SPIFFE 实现**不能**要求它们的存在以使其正常工作。

### 序列号

参数`spiffe_sequence`**应该**被设置。该序列号可以被 SPIFFE 控制平面用于许多目的，包括传播测量和更新顺序/替代。当存在时，其值**必须**为单调递增的整数，并且当 bundle 的内容被更新时必须更改。

值得注意的是，尽管 JSON 整数类型是可变宽度且没有定义最大限制，但许多实现可能将其解析为固定宽度类型。为了防止溢出，应该确保生成的类型至少具有 64 位的精度。

### 刷新提示

参数`spiffe_refresh_hint`**应该**被设置。刷新提示指示消费者应该多久检查更新。Bundle 发布者可以将刷新提示作为其密钥轮换频率的函数进行广告。值得注意的是，刷新提示还可能影响密钥撤销的传播速度。如果设置了刷新提示，其值**必须**是表示建议的消费者刷新间隔的整数，以秒为单位。正如名称所示，刷新间隔只是一个提示，根据实现的不同，消费者可以更频繁或更不频繁地检查更新。

### 密钥

参数`keys`**必须**存在。其值是一个 JWK 数组。遇到未知的密钥类型或用途的客户端**必须**忽略相应的 JWK 元素。请参阅 RFC 7517 的第 5 节以了解有关`keys`参数语义的更多信息。

`keys`参数可以包含一个空数组。发布空密钥数组的信任域表示该信任域已撤销先前发布的任何密钥。工作负载还可能遇到经处理后不产生可用密钥（即没有 JWK 通过下面描述的验证）的 bundle，并且实际上为空。这可能表明信任域已迁移到客户端不理解的新密钥类型或用途。在这两种情况下，工作负载**必须**将来自信任域的所有 SVID 视为无效和不可信。

### JWK

本节定义了作为 JWK 集合一部分包含的 JWK 元素的高级要求。JWK 元素表示单个密码密钥，用于对单个类型的 SVID 进行身份验证。虽然安全使用 JWK 的确切要求因 SVID 类型而异，但在本节中我们概述了一些顶级要求。SVID 规范必须为`use`参数（参见下面的`Public Key Use`节）定义适当的值，并且可以根据需要对其 JWK 元素设置进一步的要求或限制。

实现者**不应**包含在此处或相应的 SVID 规范中未定义的参数。

### 密钥类型

`kty` 参数必须设置，并且其行为遵循 RFC 7517 的 Section 4.1。遇到未知密钥类型的客户端必须忽略整个 JWK 元素。

### 公钥用途

`use` 参数必须设置。其值表示其具有权威性的身份文档（或 SVID）的类型。截至本文撰写时，仅支持两种 SVID 类型：`x509-svid` 和 `jwt-svid`。值区分大小写。有关 `use` 值的更多信息，请参见相应的 SVID 规范。遇到缺少 `use` 参数或未知 `use` 值的客户端必须忽略整个 JWK 元素。

## 安全注意事项

本节概述了在实施和部署 SPIFFE 控制平面时应考虑的与安全相关的注意事项。

### SPIFFE Bundle 刷新提示

SPIFFE Bundle 包括一个可选的 `refresh_hint` 字段，用于指示消费者应尝试刷新其 Bundle 副本的频率。这个值对密钥的轮换速度有明显的影响，但它也影响了密钥的撤销速度。应该仔细选择刷新提示值。

由于此字段不是必需的，因此可能会遇到没有设置 `refresh_hint` 的 SPIFFE Bundle。在这种情况下，客户端可以通过检查 SVID 有效期来使用合适的间隔。应该认识到，省略 `refresh_hint` 可能会影响信任域迅速撤销已被损坏密钥的能力。客户端应该默认使用相对较低（例如五分钟）的刷新间隔，以便及时获取更新的信任 Bundle。

### 在信任域之间重用加密密钥

本规范不鼓励在信任域之间共享加密密钥，因为这种做法会降低信任域的隔离性并引入额外的安全挑战。当一个根密钥在多个信任域之间共享时，认证和授权实现必须仔细检查标识的信任域名组件，并且信任域名组件在授权策略中必须易于表达和习惯性地表达。

假设一个天真的实现导入（即完全信任）一个特定的根密钥，并且认证系统被配置为认证链到受信任根密钥的任何 SVID 的 SPIFFE 身份。如果天真的实现未配置为仅信任特定的信任域，则任何信任域中发行的标识都可以被认证（只要 SVID 链接到受信任的根密钥）。

继续上述例子，其中天真的实现导入了特定的 CA 证书，假设认证未区分信任域并且接受链到受信任根密钥的任何 SVID。然后，授权系统将只授权特定的信任域。换句话说，授权策略需要明确配置以检查 SVID 的信任域名组件。这里的安全关注点是天真的授权实现可能盲目地相信认证系统已过滤掉不受信任的信任域。

总之，安全性的最佳实践是在信任域和根密钥之间维持一对一的映射，以减少细微（但灾难性的）认证和授权实现错误。重新使用跨信任域的根密钥的系统应确保（a）SVID 发行系统（例如 CA）在发行 SVID 前正确实现授权检查，并且（b）依赖方（即使用 SVID 的系统）正确实现强大的认证和授权系统，能够区分多个信任域。

## 附录 A. SPIFFE Bundle 示例

在下面的示例中，我们为名为`example.com`的信任域配置了初始的 SPIFFE Bundle，并演示了在根密钥轮换期间如何更新 Bundle。

`example.com`信任域的初始 X.509 CA 证书：

```
 Certificate #1:
     Data:
         Version: 3 (0x2)
         Serial Number:
             df:d0:ad:fd:32:9f:b8:15:76:f5:d4:b9:e3:be:b5:a7
     Signature Algorithm: sha256WithRSAEncryption
         Issuer: O = example.com
         Validity
             Not Before: Jan  1 08:00:45 2019 GMT
             Not After : Apr  1 08:00:45 2019 GMT
         Subject: O = example.com
         X509v3 extensions:
             X509v3 Key Usage: critical
                 Certificate Sign
             X509v3 Basic Constraints: critical
                 CA:TRUE
             X509v3 Subject Alternative Name:
                 URI:spiffe://example.com/
 [...]
```

请注意以下事项：

1. 证书是自签名的（颁发者和主题相同）；
2. 证书的 CA 标志设置为 true；
3. 证书是 SVID（具有 spiffe URI SAN）。

`example.com`的相应信任 Bundle：

```
 Trust bundle #1 for example.com:
 {
         "spiffe_sequence": 1,
         "spiffe_refresh_hint": 2419200,
         "keys": [
                 {
                         "kty": "RSA",
                         "use": "x509-svid",
                         "x5c": ["<base64 DER encoding of Certificate #1>"],
                         "n": "<base64urlUint-encoded value>",
                         "e": "AQAB"
                 }
         ]
 }
```

上述信任 Bundle 是第 1 个版本，如`spiffe_sequence`字段所示，并且指示客户端应该每 2419200 秒（或 28 天）轮询更新 Bundle。请注意，`x5c`参数包含了基于 RFC7517 Section 4.7 中所指定的 base64 编码的 DER 证书。密钥特定值（例如`n`和`e`）的编码方法在 RFC7518 Section 6 中有描述。

为了准备`example.com`的 CA 证书的过期，生成了一个替换证书，并将其添加到信任 Bundle：

```
 Certificate #2:
     Data:
         Version: 3 (0x2)
         Serial Number:
             a4:dc:5f:05:8a:a2:bf:88:9d:a4:fa:1e:9a:a5:db:74
     Signature Algorithm: sha256WithRSAEncryption
         Issuer: O = example.com
         Validity
             Not Before: Feb  15 08:00:45 2019 GMT
             Not After : Jul  1 08:00:45 2019 GMT
         Subject: O = example.com
         X509v3 extensions:
             X509v3 Key Usage: critical
                 Certificate Sign
             X509v3 Basic Constraints: critical
                 CA:TRUE
             X509v3 Subject Alternative Name:
                 URI:spiffe://example.com/
 [...]
```

在 2 月 15 日发布的`example.com`的更新后的信任 Bundle：

```
 Trust bundle #2 for example.com:
 {
         "spiffe_sequence": 2,
         "spiffe_refresh_hint": 2419200,
         "keys": [
                 {
                         "kty": “RSA”,
                         "use": "x509-svid",
                         "x5c": ["<base64 DER encoding of Certificate #1>"],
                         "n": "<base64urlUint-encoded value>",
                         "e": "AQAB"
                 },
                 {
                         "kty": “RSA”,
                         "use": "x509-svid",
                         "x5c": ["<base64 DER encoding of Certificate #2>"],
                         "n": "<base64urlUint-encoded value>",
                         "e": "AQAB"
                 }
         ]
 }
```

在 Bundle #2 中，请注意`spiffe_sequence`参数已经增加，并添加了`example.com`的第二个根证书。一旦发布并分发了这个新的信任 Bundle，验证器将接受由原始根证书或替换根证书签名的 SVID。通过提前发布替换证书，有效器有充分的机会刷新`example.com`的信任 Bundle 并了解即将到期的替换证书。

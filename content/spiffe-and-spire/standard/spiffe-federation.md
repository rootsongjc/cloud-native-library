---
weight: 6
title: "SPIFFE 联邦"
---

## 背景

SPIFFE 规范定义了建立一个平台无关的工作负载身份框架所需的文档和接口，该框架能够在不需要实现身份转换或凭证交换逻辑的情况下连接不同域中的系统。它们定义了一个“[信任域](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md#21-trust-domain)”，它作为一个身份命名空间。

SPIFFE 的本质是分散的。每个信任域都根据自己的授权行事，与驻留在其他信任域中的系统在管理上是隔离的。虽然信任域划定了行政和/或安全域，但核心的 SPIFFE 用例是在需要时跨越这些边界进行通信。因此，有必要定义一种机制，使实体可以被引入到外部信任域中，从而允许其验证由“其他”SPIFFE 授权机构颁发的凭证，并允许一个信任域中的工作负载安全地验证一个外部信任域中的工作负载。

[SPIFFE 包](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#3-spiffe-bundles)是一个包含验证特定信任域凭证所需的公钥材料的资源。本文档介绍了一种规范，用于安全地获取 SPIFFE 包，以便验证外部机构颁发的身份。其中包括有关如何提供 SPIFFE 包、如何检索 SPIFFE 包以及如何验证提供它们的端点的信息。

## 简介

SPIFFE 联邦使得在信任域之间验证身份凭证 (SVIDs) 成为可能。具体来说，它是获取验证来自不同信任域颁发的 SVIDs 所需的 SPIFFE 包的行为，并将这些包提供给执行验证的工作负载。

为了验证来自一个信任域的 SVIDs，必须拥有该信任域的包。因此，实现 SPIFFE 联邦需要在信任域之间交换 SPIFFE 包。这种交换应该定期发生，以允许信任域包的内容随时间变化。

为了实现这一点，SPIFFE 联邦定义了一个“包端点”，它是一个 URL，用于为特定的信任域提供 SPIFFE 包。还定义了一组“端点配置文件”，它们指定了包端点服务器和客户端之间使用的协议和身份验证语义。最后，本文档进一步指定了包端点客户端和服务器的行为，以及联邦关系的管理和生成的包数据。

## 目标用例

最终，SPIFFE 联邦使得工作负载能够对其他信任域中的对等方进行身份验证。这个功能对于支持各种用例至关重要，但我们希望重点关注三个核心用例。

SPIFFE 信任域经常用于将同一公司或组织中不同信任级别的环境进行分割。例如，可以在暂存和生产环境之间、PCI 和非 PCI 环境之间进行分割。在这些情况下，每个域中使用的 SPIFFE 部署共享一个共同的管理机构，并且很可能由相同的实现支持。这是一个重要的区别，因为它意味着不同的部署可以就某些事情达成一致（例如命名方案），并且每个部署的安全姿态可以被其他部署了解和理解。

其次，SPIFFE 联邦也被用于在不同公司或组织之间的信任域之间进行联邦。这种情况与第一种情况相似，我们正在对 SPIFFE 部署进行联邦，但由于可能存在的实现和管理差异，协调通常仅限于在此处描述的 SPIFFE 联邦协议中交换的数据。

最后，SPIFFE 联邦还可以为尚未部署成熟 SPIFFE 控制平面的客户端提供用例。例如，托管产品可能希望使用客户端的 SPIFFE 身份对其客户进行身份验证，而无需内部实现或部署 SPIFFE。这可以通过允许工作负载直接获取客户端的信任域绑定来实现，以便对其调用者进行身份验证，从而避免了承诺部署完整的 SPIFFE 的需求。

## SPIFFE Bundle 端点

SPIFFE Bundle 端点是一个资源（由 URL 表示），用于提供一个信任域的 SPIFFE Bundle 的副本。SPIFFE 控制平面可以同时暴露和使用这些端点，以便在它们之间传输 bundle，从而实现联邦。

SPIFFE Bundle 端点的语义类似于 OpenID Connect 规范中定义的`jwks_uri`机制，因为 bundle 包含了一个或多个用于在信任域内证明身份的公共加密密钥。Bundle 端点是一个 HTTPS URL，对 HTTP GET 请求做出 SPIFFE bundle 的响应。

### 添加和删除密钥

信任域的操作者可以根据需要（例如，作为内部密钥轮换过程的一部分）引入或删除用于颁发 SVID 的密钥。在添加新密钥时，应提前发布包含密钥的更新信任捆绑包到捆绑包端点，以便外部信任域有机会检索和内部传播新捆绑包内容；建议提前时间为捆绑包的`spiffe_refresh_hint`的 3-5 倍。至少，在使用密钥颁发 SVID 之前，新密钥必须发布到捆绑包端点。

当信任域不再颁发来自这些密钥的活动有效 SVID 时，应从信任捆绑包中删除已弃用的密钥。如果在将密钥添加到捆绑包中或从捆绑包中删除密钥时不遵循这些建议，可能会导致暂时的跨域身份验证失败。

更新信任捆绑包的要求不适用于仅用于内部使用的颁发 SVID 的密钥。

应定期轮询捆绑包端点以获取更新，因为其内容预计会随时间[更改](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#appendix-a-spiffe-bundle-example) - 常见的密钥有效期通常为几周甚至几天。客户端应以与捆绑包的`spiffe_refresh_hint`值相等的频率轮询。如果未设置，应适用合理低的默认值 - 建议为五分钟。

### 管理获取的 Bundle

Bundle 终端的客户端应在每次检索到 Bundle 时存储最新的 SPIFFE Bundle。当比较两个 Trust Bundle 的新鲜度或顺序时，应使用 Trust Bundle 的序列号字段。如果 Trust Bundle 省略了序列号，操作员应将最近检索到的 Bundle 视为最新的。

操作员可以随时在外部信任域中本地更新 SPIFFE Bundle。在这种情况下，本地更新的 Bundle 版本将被视为最新版本，直到被后续的刷新替换。

不同信任域的 Bundle 内容不得合并为单个更大的 Bundle。这样做将使一个信任域能够在验证器的眼中伪造属于另一个信任域的身份。因此，非常重要的是确保从外部信任域接收的 Bundle 保持清晰可辨，并明确反映它们所属的信任域名称。有关更多信息，请参阅安全注意事项部分。

### 终端地址的稳定性

一旦外部信任域开始依赖于特定的终端 URL，将所有终端的客户端迁移到替代终端 URL 是一个复杂且容易出错的过程。因此，最安全的做法是优先选择稳定的终端 URL。

## SPIFFE Bundle 终端的提供和使用

本规范定义了两种基于 HTTPS 的 SPIFFE Bundle 终端服务器支持的配置文件。其中一种依赖于使用 Web PKI 对终端进行身份验证，另一种则利用 SPIFFE 身份验证。SPIFFE Bundle 终端客户端必须同时支持这两种配置文件，而 SPIFFE Bundle 终端服务器必须至少支持其中一种。

支持基于 TLS 的配置文件（例如`https_web`或`https_spiffe`）的 Bundle 终端服务器必须遵守[Mozilla 中间兼容性](https://wiki.mozilla.org/Security/Server_Side_TLS#Intermediate_compatibility_.28recommended.29)要求，除非使用配置文件另有规定。

### 端点参数

在从 SPIFFE 捆绑端点检索捆绑之前，客户端必须配置以下三个参数：（1）SPIFFE 捆绑端点的 URL，（2）端点配置文件类型，以及（3）与捆绑端点关联的信任域名称。前两个参数指示捆绑端点的位置和如何进行身份验证。由于信任捆绑不包含信任域名称，客户端使用第三个参数将已下载的捆绑与特定的信任域名称关联起来。特定的端点配置文件（例如`https_spiffe`，如下所述）可以定义其他强制的配置参数。

```
Bundle Endpoint URL:		"<https://example.com/production/bundle.json>"
Bundle Endpoint Profile:	"https_web"
Trust Domain:			"prod.example.com"
```

*图 1：用于信任域[prod.example.com](http://prod.example.com/)的示例 SPIFFE 捆绑端点配置。管理员通过捆绑端点配置来检索外部信任捆绑。*

当控制平面将信任捆绑分发给工作负载时，必须通信信任域名称和信任捆绑之间的关联。有关这些参数的敏感性，请参见安全注意事项部分。

![](../../images/spiffe_bundle_distribution.png)

*图 2：在检索到外部 SPIFFE 信任捆绑后，控制平面将信任域名称和相应的捆绑分发给内部工作负载。工作负载使用此配置来验证外部信任域中的身份。有关信任捆绑内容的详细信息，请参见[SPIFFE 信任域和捆绑](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md) ，特别是[SPIFFE 捆绑格式](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#4-spiffe-bundle-format)和[SPIFFE 捆绑示例](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#appendix-a-spiffe-bundle-example)部分。*

本节中的要求适用于所有 SPIFFE 捆绑端点服务器和客户端。个别的 SPIFFE 捆绑端点配置文件可能会添加其他要求。

### 端点配置文件

端点配置文件描述了在提供或使用捆绑端点时应使用的传输协议和身份验证方法。

以下各节描述了受支持的捆绑端点配置文件。

### Web PKI（`https_web`）

`https_web`配置文件利用公信任的证书颁发机构提供了一种低摩擦的方式来配置 SPIFFE 联邦。当访问网页时，它的行为与大多数人熟悉的“https”URL 完全相同。在此配置文件中，捆绑点服务器使用由公共 CA 颁发的证书，无需额外的客户端配置；使用`https_web`配置文件类型的端点使用通常安装在现代操作系统中的相同公共 CA 证书进行身份验证。

有关使用公共证书颁发机构的更多信息，请参见安全注意事项部分。

### 端点 URL 要求

使用`https_web`的捆绑点 URL 必须将方案设置为`https`，并且在授权组件中不能包括用户信息。此规范不限制 URL 的其他组件（由[RFC 3986 第 3 节](https://tools.ietf.org/html/rfc3986#section-3)定义）。

例如，URL `https://host.example.com/trust_domain` 是 `https_web` 配置文件类型的有效 SPIFFE 捆绑点 URL。

### 端点参数

`https_web`配置文件在功能上不需要任何额外的参数，除了每个配置文件都需要的参数（即信任域名、配置文件类型和端点 URL）。

### 提供 Bundle 端点

支持`https_web`传输类型的 SPIFFE bundle 端点服务器使用标准的 TLS 保护的 HTTP（即 HTTPS）。所使用的服务器证书应由公共证书颁发机构（根据 CA/Browser 论坛的成员名单定义）颁发，并且必须将端点的 DNS 名称或 IP 地址作为 X.509 主题备用名称（或通用名称）包含在内。

作为互操作性问题，服务器不得要求对访问 bundle 端点进行客户端身份验证；这包括传输层（例如客户端证书）和 HTTP 层（例如身份验证标头）身份验证方案。

在收到正确路径的 HTTP GET 请求后，bundle 端点服务器必须回复最新版本的可用 SPIFFE bundle。响应必须以 UTF-8 编码，并应在响应上设置`Content-Type`标头为`application/json`。此规范不限制提供 SPIFFE bundle 的路径。

如果请求的 bundle 的授权机构已经更改，bundle 端点服务器可以使用 HTTP 重定向（根据[RFC 7231 第 6.4 节](https://tools.ietf.org/html/rfc7231#section-6.4)定义）进行响应。重定向的目标 URL 也必须是符合此配置文件中定义的有效的 bundle 端点 URL。服务器应使用临时重定向；重定向的支持是为了操作考虑（例如通过 CDN 提供 bundle），而不是作为永久迁移 bundle 端点 URL 的手段。有关详细信息，请参阅安全考虑事项。

### Web PKI（`https_web`）

### 提供 Bundle 端点

支持`https_web`传输类型的 SPIFFE bundle 端点服务器使用标准的 TLS 保护的 HTTP（即 HTTPS）。所使用的服务器证书应由公共证书颁发机构（根据 CA/Browser 论坛的成员名单定义）颁发，并且必须将端点的 DNS 名称或 IP 地址作为 X.509 主题备用名称（或通用名称）包含在内。

作为互操作性问题，服务器不得要求对访问 bundle 端点进行客户端身份验证；这包括传输层（例如客户端证书）和 HTTP 层（例如身份验证标头）身份验证方案。

在收到正确路径的 HTTP GET 请求后，bundle 端点服务器必须回复最新版本的可用 SPIFFE bundle。响应必须以 UTF-8 编码，并应在响应上设置`Content-Type`标头为`application/json`。此规范不限制提供 SPIFFE bundle 的路径。

如果请求的 bundle 的授权机构已经更改，bundle 端点服务器可以使用 HTTP 重定向（根据[RFC 7231 第 6.4 节](https://tools.ietf.org/html/rfc7231#section-6.4)定义）进行响应。重定向的目标 URL 也必须是符合此配置文件中定义的有效的 bundle 端点 URL。服务器应使用临时重定向；重定向的支持是为了操作考虑（例如通过 CDN 提供 bundle），而不是作为永久迁移 bundle 端点 URL 的手段。有关详细信息，请参阅安全考虑事项。

### 使用 Bundle 终点

当与`https_web` bundle 终点进行交互时，SPIFFE bundle 终点客户端使用标准的 TLS 保护的 HTTP（即 HTTPS）。在连接到终点时，必须根据[RFC 6125](https://tools.ietf.org/html/rfc6125)验证服务器证书。总结该文档，服务器证书必须由本地信任的证书颁发机构签发，且必须包含与配置的终点 URL 的主机组件匹配的 X.509 主体替代名称（或公共名称）。

在建立与 bundle 终点的 TLS 连接并验证呈现的服务器证书后，客户端发出终点 URL 指定的 HTTP GET 请求。响应的正文是一个 SPIFFE bundle。在检索信任 bundle 之前，客户端必须知道终点 URL 代表的信任域的名称，最好通过显式配置；有关详细信息，请参阅安全注意事项部分。

如果终点服务器具有 HTTP 重定向功能（如[RFC 7231 第 6.4 节](https://tools.ietf.org/html/rfc7231#section-6.4)定义的），则 bundle 终点服务器可以响应 HTTP 重定向。如果 URL 满足有效 bundle 终点 URL 的所有要求，bundle 终点客户端应遵循重定向。连接到新 URL 时，必须应用与连接到原始 URL 相同的 TLS 注意事项。bundle 终点客户端应使用配置的终点 URL 进行每个 bundle 刷新，并不应永久存储位置以供将来获取。有关详细信息，请参阅安全注意事项。

### SPIFFE 身份验证（`https_spiffe`）

`https_spiffe`配置文件使用由 SPIFFE 信任域（而不是由公共证书颁发机构签发的证书）颁发的 X509-SVID。该配置文件允许 bundle 终点避免使用网络定位器作为服务器标识的一种形式，并且通过标准 SPIFFE 机制支持自动根 CA 轮换和吊销。

除了所有配置文件所需的终点参数之外，`https_spiffe`配置文件还需要其他终点客户端参数，如下所述。

### 终点 URL 要求

使用`https_spiffe`的 bundle 终点 URL 的方案必须设置为`https`，并且在授权组件中不能包含用户信息。此规范不限制 URL 的其他组件（如[RFC 3986 第 3 节](https://tools.ietf.org/html/rfc3986#section-3)定义）。

例如，URL `https://host.example.com/trust_domain` 是`https_spiffe`配置文件类型的有效 SPIFFE bundle 终点 URL。

### 终端参数

使用`https_spiffe`配置文件的终端终端客户端必须配置终端终端服务器的 SPIFFE ID 以及获取终端终端服务器信任域的信任终端终端的安全方法。**自助终端终端**是指终端终端服务器的 SPIFFE ID 与获取的终端终端相同信任域中。配置的终端终端终端可能是自助终端终端或非自助终端终端。

如果终端是自助终端终端，则客户端需要配置一个最新的终端以启动联邦关系。客户端必须支持使用[SPIFFE Bundle 格式](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Trust_Domain_and_Bundle.md#4-spiffe-bundle-format)指定终端，并且可以支持其他格式（例如 PEM），前提是它们提供必要的根证书以验证连接。客户端依赖于此配置的终端进行第一次检索，然后存储检索到的终端以验证后续连接。有关详细信息，请参见下面的使用终端终端。

如果终端不是自助终端终端，则客户端必须单独为终端服务器的信任域进行配置。可以通过以下任何方式配置终端服务器的信任域和终端终端：

- 信任域的终端参数，该参数配置客户端使用终端配置文件根据本文档中所述的终端配置进行终端检索。请注意，客户端可以使用任何可用配置文件，并不限于`https_spiffe`。
- 未定义且超出本文档范围的获取或配置终端终端的过程，无论是自动还是静态。有关如何保护此方法的指导，请参见安全注意事项部分。

```
Bundle Endpoint URL:		"<https://example.com/global/bundle.json>"
Bundle Endpoint Profile:	"https_spiffe"
Trust Domain:			"example.com"
Endpoint SPIFFE ID:		"spiffe://example.com/spiffe-bundle-server"
Endpoint Trust Bundle:		{example.com bundle contents omitted}
```

*图 3：使用 SPIFFE 身份验证的`example.com`信任域的 SPIFFE 捆绑点端点配置示例。在此示例中，捆绑点端点是自助的，并且配置包括捆绑点端点的 SPIFFE ID 和`example.com`的信任捆绑，即此 SPIFFE ID 的信任域。此初始捆绑用于对捆绑点端点进行首次连接的身份验证并验证其 SVID。随后对该捆绑点端点的连接使用最新获取的副本进行身份验证。*

```
Bundle Endpoint URL:		"<https://example.com/production/bundle.json>"
Bundle Endpoint Profile:	"https_spiffe"
Trust Domain:			"prod.example.com"
Endpoint SPIFFE ID:		"spiffe://example.com/spiffe-bundle-server"
```

*图 4：使用 SPIFFE 身份验证的`prod.example.com`信任域的 SPIFFE 捆绑点端点配置示例。在此示例中，捆绑点端点不是自助的：`prod.example.com`的信任捆绑可通过具有 SPIFFE ID `spiffe://example.com/spiffe-bundle-server`的`example.com`获取。通过上述联邦示例已经获取了用于验证[example.com](http://example.com/)的信任捆绑。*

### 提供 Bundle 端点

支持`https_spiffe`传输类型的 SPIFFE Bundle 端点服务器使用标准的 TLS 保护的 HTTP（即 HTTPS）。服务器证书必须是有效的 X509-SVID。

作为互操作性的关注点，服务器不得要求客户端进行身份验证以访问 Bundle 端点；包括传输层（例如客户端证书）和 HTTP 层（例如身份验证头）的身份验证方案。

在收到正确路径的 HTTP GET 请求后，Bundle 端点服务器必须响应最新版本的可用 SPIFFE Bundle。操作员可以选择确切的路径值，并将其作为 Bundle 端点 URL 的一部分显示。Bundle 端点服务器必须使用 UTF-8 编码传输 Bundle，并应在响应中设置`Content-Type`头为`application/json`。

如果用于提供所请求 Bundle 的授权发生了变化，Bundle 端点服务器可以使用 HTTP 重定向（如[RFC 7231 第 6.4 节](https://tools.ietf.org/html/rfc7231#section-6.4)所定义）。重定向的目标 URL 也必须是此配置文件中定义的有效 Bundle 端点 URL，并且新目标呈现的服务器证书必须是具有与原始端点相同的 SPIFFE ID 的有效 X509-SVID。服务器应使用临时重定向；重定向的支持旨在用于运营考虑（例如通过 CDN 提供 Bundle），而不是作为永久迁移 Bundle 端点 URL 的手段。有关更多信息，请参阅安全注意事项。

### 使用 Bundle 终端点

SPIFFE bundle 终端点客户端在与`https_spiffe` bundle 终端点交互时使用标准的 TLS 保护的 HTTP（即 HTTPS）。在连接到终端点时，必须验证服务器证书是否是提供的 bundle 终端点 SPIFFE ID 的有效 X509-SVID。有关验证 X509-SVID 的信息，请参阅[SPIFFE X509-SVID](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#5-validation)规范。

自服务 bundle 终端点是指 bundle 终端点服务器的 SPIFFE ID 与正在获取的 bundle 所属的信任域位于同一信任域中。在首次连接到自服务 bundle 终端点时，客户端使用操作员提供的 SPIFFE bundle（通过 bundle 终端点参数）来验证服务器证书。随后的连接必须使用最新的可用 bundle 来验证。这样可以使外部信任域旋转密钥而不中断联邦关系。

非自服务 bundle 终端点是指 bundle 终端点服务器的 SPIFFE ID 不位于正在获取的 bundle 所属的信任域中。连接到非自服务终端点时，客户端使用与终端点 SPIFFE ID 的信任域对应的最新可用 SPIFFE bundle，该 bundle 可能是直接配置的，也可能是通过另一个联邦关系获取的。

在与 bundle 终端点建立 TLS 连接并验证呈现的服务器证书之后，客户端发出终端点 URL 指定的 HTTP GET 请求。响应的正文是一个 SPIFFE bundle。在检索信任 bundle 之前，客户端必须知道终端点 URL 所代表的信任域的名称，最好通过显式配置来获取；有关更多信息，请参阅安全注意事项部分。

终端点可以使用 HTTP 重定向进行响应（如[RFC 7231 第 6.4 节](https://tools.ietf.org/html/rfc7231#section-6.4)所定义）。如果 URL 满足有效的 bundle 终端点 URL 的所有要求，则 bundle 终端点客户端应跟随重定向。连接到新 URL 时，必须应用与连接到原始 URL 相同的 TLS 考虑。特别是，必须呈现与最初配置的相同 SPIFFE ID 的有效 X509-SVID。bundle 终端点客户端应该对每个 bundle 刷新使用配置的终端点 URL，并且不应该永久存储用于将来获取的位置。有关更多信息，请参阅安全注意事项。

## 关系生命周期

本节描述了联邦“关系”的生命周期，包括建立第一个连接、进行持续维护和终止。

联邦关系是单向的。换句话说，Alice 可以与 Bob 建立关系，但反过来不行。在这种情况下，Alice 能够验证由 Bob 颁发的身份，但 Bob 不知道如何验证由 Alice 颁发的身份。

为了实现相互身份验证，需要形成两个关系 - 每个方向一个。

### 建立关系

如“终端点参数”部分所述，为正确配置联邦关系，所有 bundle 终端点客户端需要至少三个信息：外部信任域名称、其 bundle 终端点 URL 和终端点配置文件。

bundle 终端点 URL 提供了可以找到外部信任域的 bundle 的地址，而配置文件告知客户端在调用它时应使用哪个协议。配置文件可能需要额外的特定于配置文件的参数。有关如何连接和验证 bundle 终端点的详细信息，请参阅相关的终端点配置文件子部分。

连接成功建立并接收到 bundle 副本后，将其与其所属的信任域名称一起存储。现在，可以分发 bundle 的内容（例如 CA 证书、JWT 签名密钥等），以验证源自外部信任域的 SVID。

此分发的确切方式和机制是实现细节，超出了本文档的范围。有关 SPIFFE 感知工作负载如何接收 bundle 更新的更多信息，请参阅[SPIFFE 工作负载 API](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE_Workload_API.md)规范。

### 维护关系

SPIFFE bundle 终端点客户端应定期轮询 bundle 终端点以获取更新。检测到更新后，存储代表终端点外部信任域的存储的 bundle 将进行更新。然后，将更新的内容分发，以便验证者可以根据需要添加新的密钥并删除撤销的密钥。再次强调，将此更新分发给验证者的确切方法超出了本文档的范围。

如果轮询 bundle 终端点的尝试失败，bundle 终端点客户端应在下一个轮询间隔重试，而不是立即或强制重试，因为这可能会导致 bundle 终端点服务器过载。如添加和删除密钥部分所讨论的那样，新密钥应足够提前发布，以使错过一两次轮询不会导致跨域身份验证失败。

### 终止关系

终止联邦关系就是删除对外信任域的本地副本，停止轮询其信任域终点，并确保验证器也删除了该外部信任域的终点，不再成功验证从该终点呈现的 SVID。

如果需要重新建立关系，则需要重新开始此生命周期。

### 生命周期图

![生命周期图](../../images/spiffe_federation_lifecycle.png)

## 安全考虑

本节包含与该规范相关的安全信息和观察结果。实施者和用户都应熟悉这些信息。

### 终点参数的分发

联邦关系的配置参数，包括信任域名称、终点 URL 和配置文件本身对于篡改是高度敏感的。联邦关系配置的被篡改可能会削弱或完全破坏 SPIFFE 实现所隐含的安全保证。

以下是一些例子：

- 篡改信任域名称可以使控制相应终点束端点的一方冒充任意信任域
- 篡改终点 URL，特别是与`https_web`配置文件结合使用时，攻击者可以发出欺诈性密钥并冒充相应信任域中的任何身份
- 篡改终点配置文件可以改变联邦的安全保证，例如用`https_spiffe`替换`https_web`。如果您的威胁模型包括 Web PKI 的妥协（请另请参阅下面的网络流量拦截部分），则这可能被认为是安全姿态的重大降级。

因此，控制平面管理员必须谨慎地安全源这些参数并安全地输入它们。终点束配置可以使用各种方法来获取，包括但不限于电子邮件、受 HTTPS 保护的网站、公司内部 wiki 等。无论使用的是哪种特定方法来初始分发终点配置，分发方法都需要抵御在途篡改、未经授权的静止修改以及恶意冒充。例如，电子邮件通常不具备抵御篡改或冒充（即"伪造"电子邮件）的抗性。

### 明确定义的终结点参数

每个 SPIFFE 联邦关系至少配置以下参数：

- 信任域名
- 终结点 URL
- 终结点配置文件

重要的是这三个参数要明确配置，不能从彼此中安全地推断出值。

例如，人们可能会试图从终结点 URL 的主机部分推断出 SPIFFE 信任域名。这是危险的，因为它可能允许任何可以从特定 DNS 名称提供文件的人断言同名 SPIFFE 信任域的信任根。

想象一个名为 MyPage（`mypage.example.com`）的网络托管公司，它允许客户 Alice 在`https://mypage.example.com/alice/<filename>`这样的 URL 上提供网络内容，并且 MyPage 还通过 SPIFFE 联邦与 SPIFFE 信任域名`mypage.example.com`运行 API。假设 Alice 与 Bob 建立了 SPIFFE 联邦关系，Bob 也是 MyPage 的客户，Alice 选择从`https://mypage.example.com/alice/spiffe-bundle`提供她的信任捆绑包。

![图 5：说明 Alice、Bob 和 MyPage 之间关系的图表。](../../images/spiffe_federation_mypage_example.png)

如果 Bob 的控制平面从 URL 中隐式获取信任域名，这将允许 Alice 冒充信任域`mypage.example.com`！还值得强调的是，SPIFFE 信任域名不一定是已注册的 DNS 名称，这通常使得这种假设本来就是错误的。在这个例子中，Alice 的信任域名只是`alice`。

终结点配置文件也不能从 URL 中安全地推断出。`https_web`和`https_spiffe`都使用具有相同要求的普通 HTTPS URL。没有安全的方法来区分它们。尝试使用`https_web`并回退到`https_spiffe`，或者反过来，是不充分的，原因与上述类似：从安全的角度来看，能够在特定的 HTTPS 终结点上托管使用 Web PKI 的文件与能够使用有效的 SPIFFE SVID 托管它是不等价的。

### 保持 `<信任域名, 捆绑包>` 的绑定

在对 SVID 进行身份验证时，验证者必须仅使用与 SPIFFE ID 所属的信任域名相对应的捆绑包。如果我们简单地将所有的捆绑包汇集起来，并且只要某个捆绑包对某个捆绑包有效，就接受一个 SVID，那么信任域之间就可以轻易地冒充对方的身份。换句话说，捆绑包是针对特定信任域的。

由于捆绑包在信任域和发行捆绑包的终结点之间没有自我描述的特性，且自我发布，因此在存储和传播捆绑包时，需要将 SPIFFE 联邦关系的信任域名和捆绑包终结点之间的绑定转化为信任域名和捆绑包之间的绑定。这要求不同于传统的 Web PKI，传统的 Web PKI 使用单个根证书存储来验证所有证书，而不管实际发行验证的 CA 系统是哪个。

### 捆绑包终结点服务器的可信性

捆绑包终结点服务器的可信性和完整性对于确保捆绑包所代表的信任域的安全性至关重要。这不仅包括捆绑包终结点服务器本身，还包括其运行的平台以及对其或其平台具有管理控制权的任何实体。

虽然这个事实可能看起来是不言自明的，但也有一些情况可能没有那么明显。例如，在非自服务捆绑包终结点的情况下，信任域 A 为信任域 B 提供捆绑包，信任域 B 隐式地信任信任域 A 及其管理员提供正确的捆绑包内容。类似地，如果从像 AWS S3 这样的托管平台提供捆绑包，那么代表涉及捆绑包的信任域的运营者隐式地信任 AWS 提供正确的捆绑包内容。

在选择将提供 SPIFFE 捆绑包的位置时，重要的是考虑涉及的各方的可信性。

### 捆绑包终结点的真实性

确保捆绑包终结点的真实性至关重要。这一点无法过于强调。本节探讨了确保捆绑包终结点真实性的一些考虑因素。

### 捆绑包终结点 URL 重定向

URL 重定向有两种变体：临时重定向和永久重定向。该规范通过 SHOULD 指示建议服务器只发送临时重定向，并且客户端应将所有重定向视为临时重定向，即使服务器将其标记为永久重定向。

如果客户端遵循永久重定向，那么永久重定向代表了终结点 URL 配置参数的带内自动重写。这会导致两个相关的安全风险。

首先，信任域操作员可能会试图使用永久重定向作为迁移终结点 URL 的方法。然而，没有可靠的方法来确保所有客户端都已处理了重定向，并且没有办法确保它们将永久地遵守重定向（例如，通过重启、升级、重新部署等）。如果终结点 URL 转移所有权并且客户端继续从原始终结点 URL 获取捆绑包，那么这些客户端可能会检索到由意外所有者控制的捆绑包。这在使用基于 Web PKI 的方案（如`https_web`）时尤其令人担忧，因为新域所有者有权获得公开受信任的与其相关的证书。因此，最安全的做法是选择具有长期稳定性的捆绑包终结点 URL。如果绝对需要 URL 迁移，最好使用首次获取捆绑包终结点配置的外带方法来处理，同时提前公布长期的迁移窗口。

其次，永久重定向可能被滥用为将短暂的妥协升级为更持久的妥协的机制。由于重定向是自动的，捆绑包终结点客户端操作员可能会忽略这个重定向。

临时重定向通常由 Web 主机用于操作目的：例如，允许在接收方附近的节点上提供全球稳定的 URL。禁止在 SPIFFE 联邦中使用重定向将从操作员的工具包中删除一个有用的工具。但是，临时重定向确实有安全考虑因素。并非所有的 Web 主机在其安全态势方面都是等价的，这意味着如果发生重定向，操作员可能无法获得预期的安全保证。本规范中对客户端“应该”遵循重定向的建议应该被解释为推荐的默认值：在操作价值和安全价值之间的平衡。依赖 SPIFFE 联邦捆绑包终结点的操作员可能希望禁用重定向，以避免出现意外情况。

### 网络流量拦截

虽然所有 SPIFFE 捆绑包终结点配置文件都使用的协议在很大程度上不受网络流量拦截和操纵的风险影响，但重要的是要注意，这并不一定意味着用于发放协议凭证的方案也不受影响。如果 SPIFFE 作为“零信任”解决方案的一部分部署，或者如果操作者的威胁模型中包括网络妥协，则必须特别关注用于发放捆绑包终结点服务器凭证的机制。

常见的服务器凭证发放方法是通过使用挑战 - 响应机制，其中凭证请求的授权是基于请求者能够回答发送到特定网络地址或 DNS 名称的挑战。ACME 协议就是一个例子，如果希望使用公共证书颁发机构，则应考虑补偿控制措施。特别需要注意的是捆绑包终结点服务器所在的二层网络的安全性。

最后，应指出，ACME 和公共证书颁发机构基础设施在历史上一直是稳定和可靠的。本节所描述的关注点是几十年的问题，然而，作为一种用于缓解对网络或 DNS 中信任的方式采用 SPIFFE 的操作者可能会发现这种行为令人惊讶。

### 终结点参数

破坏捆绑包终结点的一种方法是篡改终结点参数，无论是在传输中还是在终结点的客户端中以休息形式。修改其他方面真实的终结点参数可能导致降级的安全态势，甚至导致客户端与完全不同的终结点进行通信。请参阅终结点参数的分发部分以获取更多信息。

### 使用 `https_spiffe` 进行信任链接

在使用 SPIFFE 身份验证时，可以通过验证提供的 X509-SVID 来建立信任捆绑服务器的真实性，客户端可以通过各种方式获取到该信任捆绑。例如，信任域 A 的捆绑可以由信任域 B 中的一个端点提供，而信任域 B 的捆绑可以由信任域 C 中的一个端点提供，依此类推。

通过这种方式，获取的捆绑通过链式关系与提供捆绑的信任域之间建立了信任。该链式关系最终会终止于以下几种情况之一：

- 通过与自服务信任域的联邦关系
- 通过与由 Web PKI 提供的捆绑端点的联邦关系
- 在长期静态配置的信任捆绑中
- 在本文档范围之外的某个过程中

正如在 Bundle 端点服务器的可信性一节中所描述的那样，重要的是要理解该方案的安全性取决于链中的每个信任域能够履行其安全保证。链中信任域或捆绑端点服务器的妥协将导致“下一个”信任域的妥协。具有足够强大的网络拦截能力的攻击者可能会以某种方式升级此攻击，以导致链中后续的信任域可能被妥协。因此，通常不鼓励以这种方式形成长链。如果需要，管理员应花时间分析这些链，以确保所有参与的信任域符合其所需的标准。

最后，应注意到该链中的“链接”是由各个 HTTPS 请求操作（针对链中不同的捆绑端点服务器）形成的，并且这些操作可能在不同的时间发生。SPIFFE 捆绑端点客户端应记录这些 HTTPS 请求操作，并且管理员应注意保留这些日志以备将来进行法医分析（如果有必要）。

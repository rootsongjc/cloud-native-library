---
weight: 2
title: "SPIFFE 工作负载 API"
---

对于互联网工作负载而言，可移植和互操作的网络工作负载的加密身份可能是 SPIFFE 的核心用例。为了完全满足这个需求，社区必须达成一致，采用一种标准化的方式来检索、验证和与 SPIFFE 身份进行交互。本规范概述了要支持基于 SPIFFE 的身份验证系统所需的 API 签名和客户端/服务器行为。

## 引言

SPIFFE 工作负载 API 是一个 API，它提供了信息和服务，使工作负载或计算进程能够利用 SPIFFE 身份和基于 SPIFFE 的身份验证系统。它由 SPIFFE 工作负载端点提供，并由一些服务或“概要”组成。

目前，有两个概要：

- X.509-SVID 概要
- JWT-SVID 概要

这两个概要是强制性的，并且 SPIFFE 实现必须支持它们。但是，运营商可以在部署中禁用特定的概要。

本规范的未来版本可能会引入其他概要或使一个或多个概要成为可选项。

## 可扩展性

SPIFFE 工作负载 API 不能超出本规范进行扩展。希望提供扩展功能的实现者可以通过引入新的 gRPC 服务来实现，这是根据 SPIFFE 工作负载端点规范中概述的可扩展性方法来实现的。

## 服务定义

SPIFFE 工作负载 API 由一份协议缓冲区（版本 3）服务定义来定义。完整的定义可以在 workloadapi.proto 中找到。

概要作为单个`WorkloadAPI`服务中的一组相关的 RPC 实现。

## 客户端和服务器行为

### 身份标识调用者

SPIFFE 工作负载 API 支持任意数量的本地客户端，使其能够引导任何能够访问它的进程的身份标识。通常，希望为每个进程分配身份标识，其中某些进程被授予特定的身份标识。为了做到这一点，SPIFFE 工作负载 API 实现必须能够确定调用者的身份标识。

SPIFFE 工作负载端点规范规定了不直接进行客户端身份验证的要求，而是依赖于带外真实性检查。因此，SPIFFE 工作负载端点实现有责任识别调用者。然后，SPIFFE 工作负载 API 可以利用有关调用者的信息来确定要提供的适当内容。有关详细信息，请参阅 SPIFFE 工作负载端点规范中的身份验证部分。

### 连接生命周期

SPIFFE 工作负载 API 的客户端应尽可能保持打开连接的状态，等待流上接收服务器的响应消息。连接可以随时由服务器或客户端终止。在这种情况下，客户端应立即建立新连接。这有助于确保工作负载保持最新的身份相关材料。SPIFFE 工作负载 API 服务器实现者可以假设此属性，如果未能及时接收到消息，则工作负载可能过时，可能会影响其可用性。

### 流式响应

SPIFFE 工作负载 API 包括使用 gRPC 服务器端流式传输的 RPC，以促进快速传播更新，例如吊销和 CA 证书引入。这使得客户端可以循环遍历服务器响应，接受发生的更新。

服务器发送的每个流式响应消息都必须包含完整的信息集，而不仅仅是发生更改的信息。这避免了在客户端和服务器实现上进行状态跟踪的复杂性，包括对反熵机制的需求。

服务器响应消息的确切定时是特定于实现的，并且应由更改响应的事件（例如 SVID 旋转、CRL 更新等）来决定。从客户端接收到请求消息被视为生成响应的事件。换句话说，服务器响应流的第一个响应消息（基于连接的基础上）应尽快发送，不延迟。

最后，SPIFFE 工作负载 API 服务器的实现者应小心地推送更新的响应消息。一些软件可能会在接收到新信息后自动重新加载，如果所有实例同时重新加载，可能会导致一段时间的不可用。

## 默认值和删除的信息

SPIFFE Workload API 响应消息是对先前发送的响应消息的完整更新。当响应消息包含设置为默认值或空值的字段时，客户端必须将这些字段的值解释为已设置为它们的默认值或空值；在接收到字段的默认值或空值之后，先前接收到的非默认值或非空值不应由客户端保留。例如，如果客户端在`federated_bundles`字段中接收到默认值，则应舍弃先前接收到的`federated_bundles`值。

由于每个消息必须包含完整的信息集（请参阅 Stream Responses 部分），客户端应将数据的缺失解释为删除。例如，如果客户端加载了`spiffe://foo.bar`的 bundle，并接收到不包含`spiffe://foo.bar`的 bundle 的消息，则应卸载该 bundle。

### 强制字段

为了执行 profile RPC，交换的消息由强制和可选字段组成。服务器在接收到具有默认值的强制字段的消息时，应使用“InvalidArgument”gRPC 状态代码进行响应（有关更多信息，请参阅 SPIFFE Workload Endpoint 规范中的错误代码部分）。当客户端接收到具有默认值的强制字段的消息时，应报告错误并丢弃该消息。

### 联邦 Bundle

在此规范中定义的各种 RPC 可以返回来自外部信任域的信任 Bundle。包含外部 Bundle 可以使工作负载在信任域之间进行通信，并且是启用联邦的主要机制。代表外部信任域的 Bundle 称为*联邦 Bundle*。

在验证客户端时，验证器会选择代表客户端所呈现的信任域的 Bundle 进行验证。同样，在验证服务器时，客户端会使用代表服务器所在的信任域的 Bundle。如果在使用的 SVID 的 SVID 中不存在匹配的 Bundle，则对等方是不受信任的。这种方法是必需的，以解决常见 X.509 库中对 SAN URI Name Constraints 的广泛支持的缺乏。

## X.509-SVID Profile

SPIFFE Workload API 的 X.509-SVID 配置文件提供了一组 gRPC 方法，工作负载可以使用这些方法来检索 X.509-SVIDs 及其相关的信任捆绑包。该配置文件概述了这些方法的签名，以及相关的客户端和服务器行为。

### 配置文件定义

下面定义了 X.509-SVID 配置文件中的 RPC 和相关的消息。有关完整的 Workload API 服务定义，请参见 workloadapi.proto。

```protobuf
service SpiffeWorkloadAPI {
    /////////////////////////////////////////////////////////////////////////
    // X509-SVID配置文件
    /////////////////////////////////////////////////////////////////////////

    // 获取工作负载有权访问的所有SPIFFE标识的X.509-SVID，以及与之相关的信任捆绑包和CRL。随着信息的更改，后续的消息将从服务器流式传输。
    rpc FetchX509SVID(X509SVIDRequest) returns (stream X509SVIDResponse);

    // 获取信任捆绑包和CRL。对于仅需要验证SVID而不获取SVID自身的客户端非常有用。随着信息的更改，后续的消息将从服务器流式传输。
    rpc FetchX509Bundles(X509BundlesRequest) returns (stream X509BundlesResponse);

    // ... 其他配置文件的RPC ...
}

// X509SVIDRequest消息传递请求X.509-SVID的参数。目前没有此类参数。
message X509SVIDRequest { }

// X509SVIDResponse消息携带X.509-SVID和相关信息，包括用于与外部信任域联合的全局CRL集合和捆绑列表。
message X509SVIDResponse {
    // 必需。X509SVID消息列表，每个消息包括单个X.509-SVID、其私钥和信任域的捆绑。
    repeated X509SVID svids = 1;

    // 可选。ASN.1 DER编码的证书吊销列表。
    repeated bytes crl = 2;

    // 可选。工作负载应该信任的外部信任域的CA证书捆绑，按照外部信任域的SPIFFE ID进行索引。捆绑包是ASN.1 DER编码的。
    map<string, bytes> federated_bundles = 3;
}


// X509SVID消息携带单个SVID和所有相关信息，包括信任域的X.509捆绑包。
message X509SVID {
    // 必需。此条目中的SVID的SPIFFE ID
    string spiffe_id = 1;

    // 必需。ASN.1 DER编码的证书链。可以包括中间证书，但必须首先是叶子证书（或SVID本身）。
    bytes x509_svid = 2;

    // 必需。ASN.1 DER编码的PKCS#8私钥。必须是未加密的。
    bytes x509_svid_key = 3;

    // 必需。信任域的ASN.1 DER编码的X.509捆绑包。
    bytes bundle = 4;

    // 可选。操作员指定的字符串，用于在返回多个SVID时为工作负载提供其使用方式的指导。例如，`internal`和`external`分别表示内部或外部使用的SVID。
    string hint = 5;
}

// X509BundlesRequest消息传递请求X.509捆绑包的参数。目前没有这样的参数。
message X509BundlesRequest {
}

// X509BundlesResponse消息携带一组全局CRL和工作负载应该信任的信任域的映射的CA证书捆绑包。由SPIFFE ID的信任域键控。
message X509BundlesResponse {
    // 可选。ASN.1 DER编码的证书吊销列表。
    repeated bytes crl = 1;

    // 必需。工作负载应该信任的信任域的CA证书捆绑包，由SPIFFE ID的信任域键控。捆绑包是ASN.1 DER编码的。
    map<string, bytes> bundles = 2;
}
```

### Profile RPCs

### FetchX509SVID

`FetchX509SVID` RPC 流式返回 X509-SVID 和信任域以及外部信任域的 X.509 捆绑包。这些捆绑包只能用于验证 X509-SVID。

`X509SVIDRequest`请求消息当前为空，是将来扩展的占位符。

`X509SVIDResponse`响应由一个必需的`svids`字段组成，该字段必须包含一个或多个`X509SVID`消息（每个授予客户端的标识一个）。

`X509SVID`消息中的所有字段都是必需的，除了`hint`字段。当设置`hint`字段时（即非空），SPIFFE Workload API 服务器必须确保其值在任何给定的`X509SVIDResponse`消息中是唯一的。如果 SPIFFE Workload API 客户端遇到具有相同设置的`hint`值的多个`X509SVID`消息，则应选择列表中的第一个消息。

如果客户端没有权限接收任何 X509-SVID，则服务器应以“PermissionDenied”gRPC 状态代码响应（有关更多信息，请参见 SPIFFE Workload Endpoint 规范中的“错误代码”部分）。在这种情况下，客户端可以在退避后尝试重新连接到`FetchX509SVID` RPC 的另一个调用。

如流式响应所述，每个 FetchX509SVID 流返回的 X509SVIDResponse 消息都包含客户端在那个时间点上的授权 SVID 和 bundle 的完整集合。因此，如果服务器从后续响应中删除了 SVID（或全部 SVID，即返回“PermissionDenied”gRPC 状态代码），客户端应停止使用已删除的 SVID。

### FetchX509Bundles

FetchX509Bundles RPC 流返回服务器所在的信任域和外部信任域的 X.509 bundles。这些 bundles 只用于验证 X509-SVID。

X509BundlesRequest 请求消息目前为空，是未来扩展的占位符。

X509BundlesResponse 响应消息有一个强制性的 bundles 字段，必须至少包含服务器所在信任域的信任 bundle。crl 字段是可选的。

如果客户端无权接收任何 X.509 bundles，那么服务器应以“PermissionDenied”gRPC 状态代码响应（有关更多信息，请参见 SPIFFE Workload Endpoint 规范中的错误代码部分）。客户端可以在退避后尝试重新连接 FetchX509Bundles RPC。

如流式响应所述，每个 X509BundleResponse 响应在那个时间点上包含客户端的授权 X.509 bundles 的完整集合。因此，如果服务器从后续响应中删除了 bundles（或全部 bundles，即返回“PermissionDenied”gRPC 状态代码），客户端应停止使用已删除的 bundles。

### 默认身份

通常情况下，工作负载不知道它应该扮演什么身份。决定何时扮演何种身份是特定于站点的问题，因此，SPIFFE 规范不涉及如何做到这一点。

为了支持最广泛的用例，X.509-SVID 配置文件支持发出多个身份，并定义了默认身份。预计了解多个身份的工作负载可以自行进行决策。不了解如何利用多个身份的工作负载可以使用默认身份。默认身份是在 X509SVIDResponse 消息中返回的`svids`列表中的第一个。协议缓冲区确保列表的顺序得到保留。

了解如何使用多个身份的工作负载可以利用可选的`hint`字段，该字段可用于消除身份的歧义，并告知工作负载应该为何目的使用哪个身份。例如，`internal`和`external`分别表示用于内部或外部使用的 SVID。SPIFFE Workload API 实现不应支持超过 1024 字节长度的值。`hint`字段的确切值是操作员的选择，除此规范外并无限制。

工作负载有责任处理预期提示的缺失或意外存在（例如，失败、警告等）。

## JWT-SVID 配置文件

SPIFFE Workload API 的 JWT-SVID 配置文件提供了一组 gRPC 方法，可以用于工作负载获取 JWT-SVID 及其相关的信任包。该配置文件概述了这些方法的签名，以及相关的客户端和服务器行为。

### 配置文件定义

JWT-SVID 配置文件的 RPC 和相关消息如下所定义。有关完整的 Workload API 服务定义，请参见 workloadapi.proto。

```protobuf
service SpiffeWorkloadAPI {
    /////////////////////////////////////////////////////////////////////////
    // JWT-SVID配置文件
    /////////////////////////////////////////////////////////////////////////

    // 获取工作负载有权访问的所有SPIFFE标识的JWT-SVID，用于请求的受众。如果请求了可选的SPIFFE ID，则仅返回该SPIFFE ID的JWT-SVID。
    rpc FetchJWTSVID(JWTSVIDRequest) returns (JWTSVIDResponse);

    // 获取以JWKS文档格式表示的JWT信任包，由信任域的SPIFFE ID作为键。随着这些信息的更改，后续的消息将从服务器流式传输。
    rpc FetchJWTBundles(JWTBundlesRequest) returns (stream JWTBundlesResponse);

    // 根据请求的受众验证JWT-SVID。返回JWT-SVID的SPIFFE ID和JWT声明。
    rpc ValidateJWTSVID(ValidateJWTSVIDRequest) returns (ValidateJWTSVIDResponse);

    // ... 其他配置文件的RPC ...
}

message JWTSVIDRequest {
    // 必填。工作负载打算进行身份验证的受众。
    repeated string audience = 1;

    // 可选。请求的JWT-SVID的SPIFFE ID。如果未设置，则返回工作负载有权访问的所有标识的JWT-SVID。
    string spiffe_id = 2;
}

// JWTSVIDResponse消息传递JWT-SVID。
message JWTSVIDResponse {
    // 必填。返回的JWT-SVID列表。
    repeated JWTSVID svids = 1;
}

// JWTSVID消息携带JWT-SVID令牌和相关元数据。
message JWTSVID {
    // 必填。JWT-SVID的SPIFFE ID。
    string spiffe_id = 1;

    // 必填。使用JWS紧凑序列化的编码JWT。
    string svid = 2;

    // 可选。操作员指定的字符串，用于在返回多个SVID时为工作负载提供如何使用此标识的指导。例如，`internal`和`external`分别表示用于内部或外部使用的SVID。
    string hint = 3;
}

// JWTBundlesRequest消息传递请求JWT信任包的参数。目前没有请求参数。
message JWTBundlesRequest { }

// JWTBundlesReponse传递JWT信任包。
message JWTBundlesResponse {
    // 必填。以信任域的SPIFFE ID为键的JWK编码的JWT信任包。
    map<string, bytes> bundles = 1;
}

// ValidateJWTSVIDRequest消息传递JWT-SVID验证的请求参数。
message ValidateJWTSVIDRequest {
    // 必填。验证方的受众。JWT-SVID必须包含一个包含此值的受众声明才能成功验证。
    string audience = 1;

    // 必填。要验证的JWT-SVID，使用JWS紧凑序列化进行编码。
    string svid = 2;
}

// ValidateJWTSVIDReponse消息传递JWT-SVID验证结果。
message ValidateJWTSVIDResponse {
    // 必填。验证的JWT-SVID的SPIFFE ID。
    string spiffe_id = 1;

    // 必填。验证的JWT-SVID有效载荷中包含的声明。包括SPIFFE所需和非所需的声明。
    google.protobuf.Struct claims = 2;
}
```

### 配置文件 RPC

### 获取 JWTSVID

`FetchJWTSVID` RPC 允许客户端请求一个或多个特定受众的短期 JWT-SVID。

`JWTSVIDRequest` 请求消息包含一个必填的`audience`字段，该字段必须包含要嵌入返回的 JWT-SVID 中的受众声明的值。`spiffe_id`字段是可选的，用于请求特定 SPIFFE ID 的 JWT-SVID。如果未指定，服务器必须返回授权给客户端的所有身份的 JWT-SVID。

`JWTSVIDResponse` 响应消息由一个必填的`svids`字段组成，该字段必须包含一个或多个`JWTSVID`消息。

`JWTSVID`消息中的所有字段都是必填的，除了`hint`字段。当设置了`hint`字段（即非空）时，SPIFFE Workload API 服务器必须确保其值在给定的`JWTSVIDResponse`消息中的返回的 SVID 集合中是唯一的。如果 SPIFFE Workload API 客户端遇到具有相同`hint`值设置的多个`JWTSVID`消息，则应选择列表中的第一个消息。

如果客户端没有授权任何身份，或者未经授权访问`spiffe_id`字段请求的特定身份，则服务器应使用“PermissionDenied”gRPC 状态代码进行响应（有关更多信息，请参见 SPIFFE Workload 端点规范中的错误代码部分）。

### 获取 JWT Bundles

`FetchJWTBundles` RPC 返回服务器所在的信任域和外部信任域的 JWT bundles。这些 bundles 必须仅用于认证 JWT-SVID。

`JWTBundlesRequest`请求消息目前为空，是未来扩展的占位符。

`JWTBundlesResponse`响应消息由一个必填的`bundles`字段组成，该字段必须至少包含服务器所在信任域的 JWT bundle。

返回的 bundles 以[RFC 7517](https://tools.ietf.org/html/rfc7517)定义的标准 JWK Set 格式进行编码，其中包含信任域的 JWT-SVID 签名密钥。这些密钥可能仅表示 SPIFFE 信任域中的密钥子集。服务器不得在返回的 JWT bundles 中包含其他用途的密钥。

如果客户端无权接收任何 JWT bundles，则服务器应使用“PermissionDenied”gRPC 状态代码进行响应（有关更多信息，请参见 SPIFFE Workload 端点规范中的错误代码部分）。客户端可以在退避后尝试重新连接到`FetchJWTBundles` RPC 的另一个调用。

如流式响应中所述，每个`JWTBundleResponse`响应在当前时间点包含客户端的所有授权 JWT bundles 的完整集合。因此，如果服务器从后续响应中删除 bundles（或所有 bundles，即返回“PermissionDenied”gRPC 状态代码），客户端应停止使用被删除的 bundles。

### 验证 JWTSVID

`ValidateJWTSVID` RPC 代表客户端验证特定受众的 JWT-SVID。此外，服务器必须根据 JWT-SVID 规范中概述的规则解析和验证 JWT-SVID。JWT-SVID 负载中嵌入的声明应在`ValidateJWTSVIDResponse`中的`claims`字段中提供；本规范中定义的声明是必需的，但实现可能会在将它们返回给客户端之前过滤非 SPIFFE 声明。SPIFFE 声明对于互操作性是必需的。

`ValidateJWTSVIDRequest`和`ValidateJWTSVIDResponse`消息中的所有字段都是必填的。

### JWT-SVID 验证

如果客户端支持，Workload API 客户端应使用`ValidateJWTSVID`方法进行 JWT 验证，允许 SPIFFE Workload API 代表其执行验证。这样做可以避免工作负载实现验证逻辑，从而减少出错的可能性。

当与传统的 JWT 验证器进行交互时，可以使用`FetchJWTBundles`方法获取 JWKS bundles，用于验证 JWT-SVID 的签名。例如，如果 SPIFFE Workload API 可用，但 JWT 验证软件不知道 Workload API（因此无法调用`ValidateJWTSVID`），则实现可以单独检索每个 bundle 并将其提供给传统工作负载进行验证。

`FetchJWTBundles`方法返回以信任域的 SPIFFE ID 为键的 bundles。在验证 JWT-SVID 时，验证器必须使用与主题的信任域对应的 bundle。如果指定信任域的 JWT bundle 不存在，则令牌是不可信的。

## 附录 A. 示例实现状态机

为了提供清晰度，作者认为包括 SPIFFE Workload API 的客户端和服务器实现的示例状态图可能是有用的。应注意，有许多实现方式可以符合本规范，此特定实现仅供参考。

### 服务器状态机

![服务器状态机](../../images/workload_api_server_diagram.png)

1. SPIFFE Workload 端点侦听器正在启动。
2. 使用 SPIFFE Workload API 处理程序启动 gRPC 服务器，现在可以接受连接。
3. 正在验证传入的 FetchX509SVIDRequest。这包括检查强制性的安全头，并确保调用方可用身份。
4. Workload API 正在向客户端发送 FetchX509SVIDResponse。
5. Workload API 处于等待状态。从等待状态过渡需要中断或取消。中断等待状态的典型原因是响应中的信息已更新（例如，SVID 已旋转或 CRL 已更改）。
6. 对待处理的响应执行验证。确保客户端仍有权使用身份，并且请求尚未取消。
7. 服务器正在关闭流，为客户端提供正确的错误代码以表示遇到的条件。
8. 服务器遇到致命错误，必须停止。这可能发生在无法创建侦听器或 gRPC 服务器遇到致命错误的情况下。

### 客户端状态机

![客户端状态机](../../images/workload_api_client_diagram.png)

1. Workload API 客户端正在拨号 SPIFFE Workload 端点。
2. 客户端正在调用 FetchX509SVID RPC 调用，向服务器发送请求。
3. 客户端正在阻塞等待从服务器接收 X509SVIDResponse 消息。
4. 客户端正在使用从服务器响应中接收的 SVIDs、CRLs 和 bundles 更新其配置。此时，它可以将接收到的信息与当前配置进行比较，确定是否需要重新加载。
5. 客户端遇到致命错误，必须退出。
6. 客户端正在执行指数回退。

---
title: gRPC API 指南
description: 介绍如何使用我们的 gRPC API 与 TSB 进行通信的指南。
weight: 1
---

{{<callout note "Protobuf files">}}
要通过 gRPC 连接与 TSB 通信，您需要 protobuf 和 gRPC 服务定义文件。如果您希望获取它们，请联系您的 Tetrate 账户经理。
{{</callout>}}

在本指南中，您将看到如何使用 TSB gRPC API 执行常见操作。本指南中的示例使用 Go 绑定，因为这是我们默认提供的绑定，但为其他语言生成的 gRPC 客户端也可以工作。

## 初始化 gRPC 客户端

### 传输配置

在创建 gRPC 客户端时，首先要配置的是与 TSB 的连接。根据 TSB 的公开方式，您可以将连接配置为纯文本连接或 TLS 连接。

#### 配置纯文本连接

要配置纯文本连接，请使用以下 gRPC 拨号选项：

```go
opts := []grpc.DialOption{
	grpc.WithBlock(), // 在调用 Dial 时阻塞，直到连接真正建立
	grpc.WithInsecure(),
}
tsbAddress := "<tsb 主机>:<tsb 端口>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

第一个选项将指导 gRPC 客户端在 Dial 调用上阻塞，直到建立连接，第二个选项配置纯文本传输凭据。

#### 配置 TLS 连接

如果 TSB 通过 TLS 公开，则应按如下方式启用 TLS 连接：

```go
tlsConfig := &tls.Config{}  // 使用主机 CA 的默认 TLS 配置
creds := credentials.NewTLS(tlsConfig)
opts := []grpc.DialOption{
	grpc.WithBlock(), // 在调用 Dial 时阻塞，直到连接真正建立
	grpc.WithTransportCredentials(creds),
}
tsbAddress := "<tsb 主机>:<tsb 端口>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

默认 TLS 配置将使用主机 CA 来验证 TSB 服务器呈现的证书。如果证书无法由该 CA 验证，因为它是自签名的，或因为其根 CA 不是公共 CA，则请按如下方式使用自定义 CA 配置 TLS 连接：

```go
// 从文件中读取自定义 CA 捆绑包
ca, err := ioutil.ReadFile("custom-ca.crt")
if err != nil {
	return fmt.Errorf("加载 CA 文件失败: %w", err)
}
// 将 CA 捆绑包加载到 x509 证书池中
certs := x509.NewCertPool()
if ok := certs.AppendCertsFromPEM(ca); !ok {
	return errors.New("加载 CA 出错")

}
// 配置 TLS 选项以使用加载的根 CA
tlsConfig := &tls.Config{
	RootCAs: certs,
}
```

最后，如果要建立 TLS 连接，但不想验证服务器证书，可以通过以下方式配置 TLS 选项来跳过验证：

```go
tlsConfig := &tls.Config{
	InsecureSkipVerify: true,
}
```

这将指示 gRPC 客户端建立 TLS 连接，而无需验证 TSB 提交的证书。

### 身份验证

一旦传输选项已配置，您还必须设置身份验证。身份验证配置为 `credentials.PerRPCCredentials` 对象。

TSB 有两种主要的身份验证机制：基本身份验证和 JWT 令牌身份验证。

#### 基本身份验证
为了配置基本身份验证，您可以使用一个实现所需 gRPC 接口的辅助对象。以下代码显示了如何配置它的示例：

```go
// BasicAuth 是 gRPC 的 HTTP 基本凭据提供程序
type BasicAuth struct {
	Username string
	Password string
}

// GetRequestMetadata 实现 credentials.PerRPCCredentials
func (b BasicAuth) GetRequestMetadata(_ context.Context, _ ...string) (map[string]string, error) {
	auth := b.Username + ":" + b.Password
	enc := base64.StdEncoding.EncodeToString([]byte(auth))
	return map[string]string{"authorization": "Basic " + enc}, nil
}

// RequireTransportSecurity

 实现 credentials.PerRPCCredentials
func (BasicAuth) RequireTransportSecurity() bool {
	return false
}
```

有了这个对象，可以如下配置 gRPC 客户端以使用基本身份验证：

```go
auth := BasicAuth{
	Username: "username",
	Password: "password",
}

opts := []grpc.DialOption{
	grpc.WithBlock(), // 在调用 Dial 时阻塞，直到连接真正建立
	grpc.WithPerRPCCredentials(auth),
}
tsbAddress := "<tsb 主机>:<tsb 端口>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

#### JWT 令牌身份验证

对于基于 JWT 令牌的身份验证，使用一个支持对象来简化配置 gRPC 选项：

```go
// TokenAuth 是 gRPC 的基于 JWT 的凭据提供程序
type TokenAuth string

// GetRequestMetadata 实现 credentials.PerRPCCredentials
func (t TokenAuth) GetRequestMetadata(_ context.Context, _ ...string) (map[string]string, error) {
	return map[string]string{"x-tetrate-token": string(t)}, nil
}

// RequireTransportSecurity 实现 credentials.PerRPCCredentials
func (TokenAuth) RequireTransportSecurity() bool {
	return false
}
```

然后，使用以下 `DialOptions` 配置 gRPC 客户端：

```go
auth := TokenAuth("jwt-token")

opts := []grpc.DialOption{
	grpc.WithBlock(), // 在调用 Dial 时阻塞，直到连接真正建立
	grpc.WithPerRPCCredentials(auth),
}
tsbAddress := "<tsb 主机>:<tsb 端口>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

## 示例：创建组织、租户和工作空间

以下示例演示了如何使用配置的连接实例化不同 TSB gRPC 客户端，以访问 TSB 的不同 API。

```go
var (
	tsbAddress = "<tsb 主机>:<tsb 端口>"
	username   = "username"
	password   = "password"

	tlsConfig = &tls.Config{
		// 添加任何自定义 TLS 选项
	}
)

// ----------------------------------
// 连接配置
// ----------------------------------

opts := []grpc.DialOption{
	grpc.WithBlock(),
	grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig)),
	grpc.WithPerRPCCredentials(BasicAuth{
		Username: username,
		Password: password,
	}),
}

cc, err := grpc.DialContext(context.Background(), tsbAddress, opts...)
if err != nil {
	panic(err)
}

// ------------------------------------------------
// 创建 gRPC 客户端并使用 API
// ------------------------------------------------

var (
	orgsClient       = v2.NewOrganizationsClient(cc)
	tenantsClient    = v2.NewTenantsClient(cc)
	workspacesClient = v2.NewWorkspacesClient(cc)
)

ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

org, err := orgsClient.CreateOrganization(ctx, &v2.CreateOrganizationRequest{
	Name: "myorg",
	Organization: &v2.Organization{
		DisplayName: "My Organization",
		Description: "Organization created using the TSB gRPC API",
	},
})
if err != nil {
	panic(err)
}
fmt.Printf("Created organization %q (%s)\n", org.DisplayName, org.Fqn)

tenant, err := tenantsClient.CreateTenant(ctx, &v2.CreateTenantRequest{
	Parent: org.Fqn, // 在我们刚刚创建的组织中创建租户
	Name:   "mytenant",
	Tenant: &v2.Tenant{
		DisplayName: "My Tenant",
		Description: "Tenant created using the TSB gRPC API",
	},
})
if err != nil {
	panic(err)
}
fmt.Printf("Created tenant %q (%s)\n", tenant.DisplayName, tenant.Fqn)

ws, err := workspacesClient.CreateWorkspace(ctx, &v2.CreateWorkspaceRequest{
	Parent: tenant.Fqn, // 在我们刚刚创建的租户中创建工作空间
	Name:   "myworkspace",
	Workspace: &v2.Workspace{
		DisplayName: "My Workspace",
		Description: "Workspace created using the TSB gRPC API",
		NamespaceSelector: &typesv2.NamespaceSelector{
			Names: []string{"*/*"},
		},
	},
})
if err != nil {
	panic(err)
}
fmt.Printf("Created workspace %q (%s)\n", ws.DisplayName, ws.Fqn)
```

## 附录

### 从 TSB 获取 JWT 令牌

第一次连接到 TSB 时，您可能没有令牌。如果要使用基于令牌的身份验证，您可以使用基本身份验证凭据交换会话令牌以连接到 TSB。

以下示例显示了一个可用于获取访问令牌的辅助函数，您可以将其配置在基于 JWT 令牌的身份验证选项中：

```go
func GetToken(ctx context.Context, address string, username string, password string) (string, error) {
	tlsConfig := &tls.Config{
		// 添加任何自定义 TLS 选项
	}
	creds := credentials.NewTLS(tlsConfig)
	opts := []grpc.DialOption{
		grpc.WithBlock(),
		grpc.WithTransportCredentials(creds),
		// 请注意，我们在此处未配置每个 RPC 凭据。这将创建到 TSB IAM API 的连接，并且凭据将在请求负载中提供
	}

	cc, err := grpc.DialContext(ctx, address, opts...)
	if err != nil {
		return "", err
	}
	defer func() { _ = cc.Close() }()

	iamClient := iam.NewAuthenticationClient(cc)

	tokens, err := iamClient.Authenticate(ctx, &iam.Credentials{
		Auth: &iam.Credentials_Basic{
			Basic: &iam.Credentials_BasicAuth{
				Username: username,
				Password: password,
			},
		},
	})

	if err != nil {
		return "", err
	}

	return tokens.BearerToken, nil
}
```

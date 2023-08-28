---
title: gRPC API Guide
menu-title: Guide
description: Guide describing how to use our gRPC API for communication with TSB.
---

:::note Protobuf files
To communicate with TSB over a gRPC connection you will need the protobuf and
gRPC service definition files. Please contact your Tetrate account manager if
you wish to acquire them.
:::

In this guide you'll see how you can use the TSB gRPC API to perform common
operations on the platform. The examples in this guide use the Go bindings, as
those are the ones we provide on request by default, but gRPC clients generated
for other languages will work as well.

## Initializing the gRPC client

### Transport configuration

The first thing to configure when creating the gRPC client is the connection to
TSB. Depending how TSB is exposed, you can configure the connection as a
plain-text connection or as a TLS one.

#### Configuring a plain-text connection

To configure a plain text connection, use the following gRPC dial options:

```go
opts := []grpc.DialOption{
	grpc.WithBlock(), // Block when calling Dial until the connection is really established
	grpc.WithInsecure(),
}
tsbAddress := "<tsb host>:<tsb port>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

The first option will instruct the gRPC client to block on the Dial call until
the connection has been established, the second option configures the plain-text
transport credentials.

#### Configuring a TLS connection

If TSB is exposed via TLS, you should enable TLS connections as follows:

```go
tlsConfig := &tls.Config{}  // Default TLS configuration to use the host CA
creds := credentials.NewTLS(tlsConfig)
opts := []grpc.DialOption{
	grpc.WithBlock(), // Block when calling Dial until the connection is really established
	grpc.WithTransportCredentials(creds),
}
tsbAddress := "<tsb host>:<tsb port>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)

```

The default TLS configuration will use the host CA to verify the certificate
presented by the TSB server. If the certificate cannot be validated by that CA
because it's self-signed, or because its root CA is not a public one, configure
the TLS connection with a custom CA as follows:

```go
// Read the custom CA bundle from a file
ca, err := ioutil.ReadFile("custom-ca.crt")
if err != nil {
	return fmt.Errorf("failed to load CA file: %w", err)
}
// Load the CA bundle into an x509 certificate pool
certs := x509.NewCertPool()
if ok := certs.AppendCertsFromPEM(ca); !ok {
	return errors.New("error loading CA")

}
// Configure the TLS options to use the loaded root CA
tlsConfig := &tls.Config{
	RootCAs: certs,
}
```

Finally, if you want to establish a TLS connection, but don't want to validate
the server certificate, you can skip the validation by configuring the TLS
options as follows:

```go
tlsConfig := &tls.Config{
	InsecureSkipVerify: true,
}
```

This will instruct the gRPC client to establish a TLS connection without
validating the certificate presented by TSB.

### Authentication

Once the transport options have been configured, you must set authentication as
well. Authentication is configured as a `credentials.PerRPCCredentials` object.

TSB has two main authentication mechanisms: basic authentication and JWT token
authentication.

#### Basic Auth
In order to configure basic authentication, you can use a helper object that
implements the gRPC interfaces you need. The following code shows an example of
how to configure it:

```go
// BasicAuth is an HTTP Basic credentials provider for gRPC
type BasicAuth struct {
	Username string
	Password string
}

// GetRequestMetadata implements credentials.PerRPCCredentials
func (b BasicAuth) GetRequestMetadata(_ context.Context, _ ...string) (map[string]string, error) {
	auth := b.Username + ":" + b.Password
	enc := base64.StdEncoding.EncodeToString([]byte(auth))
	return map[string]string{"authorization": "Basic " + enc}, nil
}

// RequireTransportSecurity implements credentials.PerRPCCredentials
func (BasicAuth) RequireTransportSecurity() bool {
	return false
}
```

With this object in place, configure the gRPC client to use Basic Authentication
as follows:

```go
auth := BasicAuth{
	Username: "username",
	Password: "password",
}

opts := []grpc.DialOption{
	grpc.WithBlock(), // Block when calling Dial until the connection is really established
	grpc.WithPerRPCCredentials(auth),
}
tsbAddress := "<tsb host>:<tsb port>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

#### JWT Token Auth

For JWT Token-based authentication, use a supporting object that will facilitate
configuring the gRPC options:

```go
// TokenAuth is a JWT based credentials provider for gRPC
type TokenAuth string

// GetRequestMetadata implements credentials.PerRPCCredentials
func (t TokenAuth) GetRequestMetadata(_ context.Context, _ ...string) (map[string]string, error) {
	return map[string]string{"x-tetrate-token": string(t)}, nil
}

// RequireTransportSecurity implements credentials.PerRPCCredentials
func (TokenAuth) RequireTransportSecurity() bool {
	return false
}
```

Then, configure the gRPC client with the following `DialOptions`:

```go
auth := TokenAuth("jwt-token")

opts := []grpc.DialOption{
	grpc.WithBlock(), // Block when calling Dial until the connection is really established
	grpc.WithPerRPCCredentials(auth),
}
tsbAddress := "<tsb host>:<tsb port>"
cc, err := grpc.DialContext(ctx, tsbAddress, opts...)
```

## Example: creating organizations, tenants and workspaces

The following example demonstrates how you can instantiate the different TSB
gRPC clients using the configured connection to access TSB's different APIs.

```go
var (
	tsbAddress = "<tsb host>:<tsb port>"
	username   = "username"
	password   = "password"

	tlsConfig = &tls.Config{
		// Add any custom TLS options
	}
)

// ----------------------------------
// Connection configuration
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
// gRPC client creation and API usage
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
	Parent: org.Fqn, // Create the tenant in the organization we just created
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
	Parent: tenant.Fqn, // Create the workspace in the tenant we jsut created
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

## Appendix

### Obtaining JWT tokens from TSB

The first time you connect to TSB, you may not have a token. If you want to use
token-based authentication, you can exchange the basic authentication
credentials for a session token to connect to TSB.

The following example shows a helper function that can be used to get an access
token that you can configure in the JWT Token-based authentication options:

```go
func GetToken(ctx context.Context, address string, username string, password string) (string, error) {
	tlsConfig := &tls.Config{
		// Add any custom TLS options
	}
	creds := credentials.NewTLS(tlsConfig)
	opts := []grpc.DialOption{
		grpc.WithBlock(),
		grpc.WithTransportCredentials(creds),
		// Note we are not configuring per RPC credentials here. This will create
		// a connection to the TSB IAM API and credentials will be provided in
		//  in the request payload
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

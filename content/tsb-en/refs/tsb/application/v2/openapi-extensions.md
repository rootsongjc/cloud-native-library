---
title: OpenAPI Extensions
description: OpenAPI Extensions available to configure APIs.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

OpenAPI Extensions available to configure APIs.





## OpenAPIExtension {#tetrateio-api-tsb-application-v2-openapiextension}

Metadata describing an extension to the OpenAPI spec.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the OpenAPI extension as it should appear in the OpenAPI document.
For example: x-tsb-service

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


appliesTo

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Parts of the OpenAPI spec where this custom extension is allowed.
This is a list of names of the OpenAPI elements where the extension is supported.
For example: ["info", "path"]

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


required

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Flag that configures if the extension is mandatory for the elements where it
is supported.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OpenAPIExtensions {#tetrateio-api-tsb-application-v2-openapiextensions}

Available OpenAPI extensions to configure APi Gateway features in Service
Bridge.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


xTsbService

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Short name of the service in the TSB service registry where the path is
exposed. If the extension is configured in the `info` section, all paths in
the spec will be mapped to this service.

This service name will be used to generate all the routes for traffic
coming to the associated paths.

OpenAPI extension name: x-tsb-service<br/>
Applies to: info, path<br/>
Required: Required unless x-tsb-redirect or x-tsb-clusters is defined for the target paths.

Example:

```yaml
openapi: 3.0.0
info:
  title: Sample API
  version: 0.1.9
  x-tsb-service: productpage.bookinfo
paths:
  /users:
    x-tsb-service: productpage.bookinfo
    get:
      summary: Returns a list of users.
```

$docs_field_name = x-tsb-service

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbRedirect

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Redirect](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-redirect) <br/> Configures a redirection for the given path.
If a redirection is configured for a given path, the `x-tsb-service`
extension can be omitted.

OpenAPI extension name: x-tsb-redirect<br/>
Applies to: path<br/>
Required: false

Example:

```yaml
paths:
  /users:
    x-tsb-redirect:
      uri: /v2/users
    get:
      summary: Returns a list of users.
```

$docs_field_name = x-tsb-redirect

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbTls

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings) <br/> Configures the TLS settings for a given server. If omitted, the
server will be configured to serve plain text connections.

OpenAPI extension name: x-tsb-redirect<br/>
Applies to: server<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    x-tsb-tls:
      mode: SIMPLE
      secretName: api-certs
```

$docs_field_name = x-tsb-tls

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbCors

</td>

<td>

[tetrateio.api.tsb.gateway.v2.CorsPolicy](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-corspolicy) <br/> Configures CORS policy settings for the given server.
Note that Service Bridge does not currently support per-path CORS
settings, so this applies at a server level.

OpenAPI extension name: x-tsb-cors<br/>
Applies to: server<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    x-tsb-cors:
      allowOrigin:
        - "*"
```

$docs_field_name = x-tsb-cors

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbAuthentication

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authentication](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication) <br/> Configures Authentication rules for the given server.
This extension must be configured if the Authorization is configured
with rules based on JWT tokens.

OpenAPI extension name: x-tsb-authentication<br/>
Applies to: server<br/>
Required: Required if Authorization is based on JWT tokens.

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    x-tsb-authentication:
      jwt:
        issuer: https://www.googleapis.com/oauth2/v1/certs
        audience: bookinfo
```

$docs_field_name = x-tsb-authentication

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbExternalAuthorization

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authorization.ExternalAuthzBackend](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization-externalauthzbackend) <br/> Configures an external authorization server to handle all authorization requests
for the configured server.

OpenAPI extension name: x-tsb-external-authorization<br/>
Applies to: server<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    x-tsb-external-authorization:
      uri: http://authz-server.example.com
      includeRequestHeaders:
        - Authorization # forwards the header to the authorization service.
```

$docs_field_name = x-tsb-external-authorization

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbJwtAuthorization

</td>

<td>

[tetrateio.api.tsb.application.v2.OpenAPIExtensions.JWTAuthz](../../../tsb/application/v2/openapi_extensions#tetrateio-api-tsb-application-v2-openapiextensions-jwtauthz) <br/> Configures Authorization based on JWT tokens.

Note that if this is configured, the `x-tsb-authentication` extension must
be configured for the servers so the tokens can be properly validated and
trusted before reading their contents to enforce access control rules.

This can be applied at the server or path level. When applied at the server level,
the authorization rules will be enforced for all paths in that server.

OpenAPI extension name: x-tsb-jwt-authorization<br/>
Applies to: server, path<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    x-tsb-authorization:
      claims:
        - iss: https://www.googleapis.com/oauth2/v1/certs
          sub: expected-subject
          other:  # Additional claims to require int he token
            group: engineering
paths:
  /users:
    x-tsb-authorization:  # Override the server settings for the given path
      claims:
        - other:
            group: admin
```

$docs_field_name = x-tsb-jwt-authorization

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbRatelimiting

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimitSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings) <br/> Configures settings for ratelimiting requests

This can be applied at the server, path and operation level.
Each rate limit setting is independent of the other.
Top level fields such as `failClosed` and `timeout`
can be only be specified at the server level. 
The dimensions are automatically populated based on the path
attributes, and users are allowed to append more dimensions
as well

OpenAPI extension name: x-tsb-ratelimiting<br/>
Applies to: server, path, operation<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    # Ratelimit at 10 requests/minute for every HTTP GET request 
    # with a unique value in the x-user-id header
    x-tsb-ratelimiting:
      failClosed: false
      timeout: 0.03s
      rules: 
      - dimensions:
          - header:
              name: x-user-id
          - header:
              name: ":method"
              value:
                exact: GET
        limit:
          requestsPerUnit: 10
          unit: MINUTE
paths:
  /users:
    # Ratelimit at 5 requests/second for every HTTP request
    # with a path value of /users
    x-tsb-ratelimiting:
      rules:
      - limit:
          requestsPerUnit: 5
          unit: SECOND
    post:
      # Ratelimit at 10 requests/second for every HTTP request
      # with a values /users for path and POST for method
      x-tsb-ratelimiting:
        rules:
        - limit:
            requestsPerUnit: 10
            unit: SECOND
```

$docs_field_name = x-tsb-ratelimiting

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbExternalRatelimiting

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings) <br/> Configures settings for ratelimiting requests using an external ratelimit server
This can be applied at the server, path and operation level.
Each setting is independent of the other.
Top level fields such as `domain` and `rateLimitServerUri` must 
only be specified at the server level. 
The 'headers` field within the `headerValueMatch` 
dimension field is automatically populated
when this annotation is used at the path and operation level
and the `headers` field is unset.
Users are allowed to append more values as well. 

OpenAPI extension name: x-tsb-external-ratelimiting<br/>
Applies to: server, path, operation<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
servers:
  - url: http://api.example.com/v1
    # This configuration will emit a list of descriptors - 
    # ("remote_address", "<trusted address from x-forwarded-for>"),
    # ("header_match", "desc-value-1") only for GET requests,
    # ("desc-key-1", "<header_value_queried_from_header>") only when
    # the request contains the header x-user-id
    # These descriptors are sent as a request to grpc://ratelimiter.bar.com
    # with the domain field set to "my-api-domain"
    # The response from the server decides whether this request will be
    # ratelimited or not.
    x-tsb-external-ratelimiting:
      domain: "my-api-domain"
      rateLimitServerUri: "grpc://ratelimiter.bar.com"
      rules:
      - dimensions:
          - requestHeaders:
              headerName: "x-user-id"
              descriptorKey: "desc-key-1"    
          - headerValueMatch:
              descriptorValue: "desc-value-1"
              headers: 
                ":method":
                exact: "GET"
          - remoteAddress: {} 
paths:
  /users:
    # This configuration will emit the descriptor 
    # ("header_match", "desc-value-2") when the :path header is set to /users.
    # This descriptor is sent as part of the request to grpc://ratelimiter.bar.com
    # with the domain field set to "my-api-domain".
    # The response from the server decides whether this request will be
    # ratelimited or not.
    x-tsb-external-ratelimiting:
      rules:
      - dimensions:
          - headerValueMatch:
              descriptorValue: "desc-value-2"
    post:
      # This configuration will emit the descriptor 
      # ("header_match", "desc-value-3") when the :path header is set to /users
      # and the :method header is set to GET.
      # This descriptor is sent as part of the request to grpc://ratelimiter.bar.com
      # with the domain field set to "my-api-domain"
      # The response from the server decides whether this request will be
      # ratelimited or not.
      x-tsb-external-ratelimiting:
        rules:
        - dimensions:
            - headerValueMatch:
                descriptorValue: "desc-value-3"
```

$docs_field_name = x-tsb-external-ratelimiting

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbWasmExtensions

</td>

<td>

[tetrateio.api.tsb.application.v2.OpenAPIWasmExtensionAttachment](../../../tsb/application/v2/openapi_extensions#tetrateio-api-tsb-application-v2-openapiwasmextensionattachment) <br/> Configures WASM extensions associated to the Ingress Gateway generated from the API OpenAPI definition.
This list of extensions can be assigned to the `info` level as there is only one IngressGateway per API.

OpenAPI extension name: x-tsb-wasm-extensions<br/>
Applies to: info<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
info:
  title: Sample API
  version: 0.1.9
  x-tsb-wasm-extensions:
   - name: wasm-header
     config:
       header: x-wasm-header
         value: api-tsb
paths:
  /users:
    x-tsb-service: productpage.bookinfo
    get:
      summary: Returns a list of users.
```

$docs_field_name = x-tsb-wasm-extensions

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbWasmDefinitions

</td>

<td>

[tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension) <br/> Configures WASM extensions definitions used in the attachments from the API OpenAPI definition.
This list of extensions can be assigned to the `info` level.
Inline extension definition is ONLY allowed when using App Ingress. When using it in a TSB application,
only extensions enabled in the TSB extensino catalog can be referenced.

OpenAPI extension name: x-tsb-wasm-definitions<br/>
Applies to: info<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
info:
  title: Sample API
  version: 0.1.9
  x-tsb-wasm-extensions:
   - name: wasm-header
     config:
       header: x-wasm-header
         value: api-tsb
  x-tsb-wasm-definitions:
    - fqn: extensions/wasm-header
      url: oci://docker.io/example/my-wasm-extension:1.0
      source: https://github.com/example/wasm-extension
      phase: AUTHN
      priority: 200
      config:
        header: x-wasm-header
        value: def-value
paths:
  /users:
    x-tsb-service: productpage.bookinfo
    get:
      summary: Returns a list of users.
```

$docs_field_name = x-tsb-wasm-definitions

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbWaf

</td>

<td>

[tetrateio.api.tsb.security.v2.WAFSettings](../../../tsb/security/v2/waf_settings#tetrateio-api-tsb-security-v2-wafsettings) <br/> Configures a set of WAF rules to be applied to incoming traffic.

OpenAPI extension name: x-tsb-waf<br/>
Applies to: info<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
info:
  title: Sample API
  version: 0.1.9
  x-tsb-waf:
    rules:
      - Include @recommended-conf
      - SecResponseBodyAccess Off
      - Include @owasp_crs/*.conf
paths:
  /users:
    x-tsb-service: productpage.bookinfo
    get:
      summary: Returns a list of users.
```

$docs_field_name = x-tsb-waf

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbClusters

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RouteToClusters](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-routetoclusters) <br/> Short name of the clusters that contain ingress gateways where the path is
exposed. If the extension is configured in the `info` section, all paths in
the spec will be mapped to clusters.

This clusters name will be used to generate all the routes for traffic
coming to the associated paths.

OpenAPI extension name: x-tsb-clusters<br/>
Applies to: info, path<br/>
Required: Required unless x-tsb-redirect or x-tsb-service is defined for the target paths.

Example:

```yaml
openapi: 3.0.0
info:
  title: Sample API
  version: 0.1.9
  x-tsb-clusters:
   clusters:
     - name: c1 # the target gateway IPs will be automatically determined
       weight: 100
paths:
  /users:
    x-tsb-clusters:
      clusters:
        - name: c2
          weight: 90
        - name: c3
          weight: 10
    get:
      summary: Returns a list of users.
```

$docs_field_name = x-tsb-clusters

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xTsbTransit

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If this flag is activated (set to true), only the specified path(s) for a given server will be accessible
exclusively within the mesh network. This implies that any external traffic aiming to reach these paths
would be blocked, promoting network isolation and enhanced security.

This setting plays a crucial role in traffic forwarding across two different clusters that may not
have a direct connection to each other. It facilitates communication through the mesh network, creating
an indirect link between them. Thus, even if a direct route does not exist, information exchange can still take place.

If this extension is applied under the server of the 'info' section, it affects all paths listed
in the 'spec' for that particular server. Consequently, these paths become exclusive to the mesh network,
restricting their accessibility from outside the network.

However, if this extension is applied to a single server listed in the path section, its impact is more specific.
It only affects that particular path mentioned in the 'spec' for that server. In turn, this single path is
made exclusive to the mesh network, shielding it from external access. This granular level of control can be
beneficial in cases where only a specific path needs to be isolated, while others remain accessible.

In both cases, this helps in controlling and managing traffic flow, especially in large distributed systems where
security and traffic management are critical. This granular control allows for a flexible, security-focused approach
to managing network traffic within the mesh network.

OpenAPI extension name: x-tsb-transit<br/>
Applies to: server<br/>
Required: false

Example:

```yaml
openapi: 3.0.0
info:
  title: Sample Internal API
  version: 0.1.9
  servers:
   - url: http://api.example.com/v1
     x-tsb-transit: false
paths:
  /users:
    get:
      summary: Returns a list of users that can be accessed from outside.
  /internalusers:
    servers:
     - url: http://internal.api.example.com/v1
       x-tsb-transit: true
    get:
      summary: Returns a list of internal users only accessible within the mesh.
```

$docs_field_name = x-tsb-transit

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### JWTAuthz {#tetrateio-api-tsb-application-v2-openapiextensions-jwtauthz}

Configures authorization rules based on the JWT token in an incoming request.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


claims

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.Subject.JWTClaims](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-subject-jwtclaims) <br/> List of claims to be required for incoming requests.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OpenAPIWasmExtensionAttachment {#tetrateio-api-tsb-application-v2-openapiwasmextensionattachment}

OpenAPIWasmExtensionAttachment defines the WASM extension attached in an OpenAPI specification
including the name to identify the extension and also the specific configuration
that will override the global extension configuration.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the extension to be executed. The Organization will be inferred by the API Org owner.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


config

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Configuration parameters sent to the WASM plugin execution.
This configuration will overwrite the one specified globally in the extension.
This config will be passed as-is to the extension. It is up to the extension to deserialize the config and use it.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




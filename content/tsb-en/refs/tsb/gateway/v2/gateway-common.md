---
title: Gateway Common Configuration Messages
description: Configurations used to build gateways.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Configurations used to build gateways.





## ClusterDestination {#tetrateio-api-tsb-gateway-v2-clusterdestination}





  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the destination cluster. Only one of name or labels
must be specified.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Labels associated with the cluster. Any cluster with matching
labels will be selected as a target. Only one of name or labels
must be specified.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


network

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The network associated with the destination clusters. In addition to
name/label selectors, only clusters matching the selected networks
will be used as a target. At least one of name/labels, and/or network
must be specified.

Deprecated: The `network` field is deprecated and will be removed in future releases.
Only `labels` matching against the cluster object is supported.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


weight

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The weight for traffic to a given destination.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CorsPolicy {#tetrateio-api-tsb-gateway-v2-corspolicy}





  
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


allowOrigin

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The list of origins that are allowed to perform CORS requests. The content will be serialized
into the Access-Control-Allow-Origin header. Wildcard * will allow all origins.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


allowMethods

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of HTTP methods allowed to access the resource. The content will be serialized into the
Access-Control-Allow-Methods header.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


allowHeaders

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of HTTP headers that can be used when requesting the resource. Serialized to
Access-Control-Allow-Headers header.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


exposeHeaders

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A white list of HTTP headers that the browsers are allowed to access. Serialized into
Access-Control-Expose-Headers header.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


maxAge

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Specifies how long the results of a preflight request can be cached. Translates to the
Access-Control-Max-Age header.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


allowCredentials

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Indicates whether the caller is allowed to send the actual request (not the preflight) using
credentials. Translates to Access-Control-Allow-Credentials header.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ExternalRateLimitServiceSettings {#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings}

Configuration for ratelimiting using an external ratelimit server
The ratelimit server must expose
[Envoy's Rate Limit Service gRPC API](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/rate_limit#config-rate-limit-service).

If the rate limit service is called, and the response for any of
the descriptors is over limit, a 429 response is returned. The rate
limit filter also sets the x-envoy-ratelimited header.

If there is an error in calling rate limit service or rate limit
service returns an error and failure_mode_deny is set to true, a
500 response is returned.



  
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


domain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The rate limit domain to use when calling the rate limit service.
Ratelimit settings are namespaced to a domain.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_bytes: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


failClosed

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If the rate limit service is unavailable, the request will fail
if failClosed is set to true. Defaults to false.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rateLimitServerUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The URI at which the external rate limit server can be reached.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_bytes: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


rules

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitRule](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitrule) <br/> _REQUIRED_ <br/> A set of rate limit rules.
Each rule describes a list of dimension to match on.
Once matched, a list of descriptors are sent
to the external rate limit server

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


timeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The timeout in seconds for the external rate limit server RPC.
Defaults to 0.020 seconds (20ms).
Traffic will not be allowed to the destination if failClosed is set to true
and the request to the rate limit server times out.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tls

</td>

<td>

[tetrateio.api.tsb.auth.v2.ClientTLSSettings](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-clienttlssettings) <br/> Configure TLS parameters to be used when connecting to the external
rate limit server.
By default, the client will not validate the certificates
it is presented with.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### RateLimitDimension {#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension}

RateLimitDimension is a set of conditions to match HTTP requests
Once the conditions are satisfied,
corresponding descriptors (set of keys and values) are emitted and
sent to the external rate limit server. The server is expected to
make a rate limit decision based on these descriptors.
Please go through the [Envoy RateLimit descriptor](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/common/ratelimit/v3/ratelimit.proto#envoy-v3-api-msg-extensions-common-ratelimit-v3-ratelimitdescriptor)
to get more information on descriptors



  
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


sourceCluster

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitDimension.SourceCluster](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-sourcecluster) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on source envoy cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


destinationCluster

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitDimension.DestinationCluster](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-destinationcluster) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on destination envoy cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


remoteAddress

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitDimension.RemoteAddress](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-remoteaddress) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on remote address of client.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


requestHeaders

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitDimension.RequestHeaders](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-requestheaders) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on the value of certain request headers.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


headerValueMatch

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitDimension.HeaderValueMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-headervaluematch) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on the existence of certain request headers.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### HeaderValueMatch {#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-headervaluematch}

Emit descriptor entry - a key-value pair of the form `("header_match",
"<descriptor_value>")`, where `descriptor_value` is a user
specified value corresponding to a header match event.



  
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


headers

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch)> <br/> _REQUIRED_ <br/> Specifies a set of headers that the rate limit action should
match on. The action will check the request’s headers against
all the specified headers in the config. A match will happen if
all the headers in the config are present in the request with
the same values (or based on presence if the value field is not
in the config).  The header keys must be lowercase and use
hyphen as the separator, e.g. x-request-id.

</td>

<td>

map = {<br/>&nbsp;&nbsp;min_pairs: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


descriptorValue

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The value to use in the descriptor entry.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_bytes: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


#### RequestHeaders {#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension-requestheaders}

Emit descriptor entry - a key-value pair of the form
`("<descriptor_key>", "<header_value_queried_from_header>")`
where `descriptor_key` is a user specified key to emit when the
HTTP header is seen.



  
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


headerName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The header name to be queried from the request headers. The header’s
value is used to populate the value of the descriptor entry for the
descriptor_key.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_bytes: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


descriptorKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The key to use in the descriptor entry.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_bytes: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


### RateLimitRule {#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitrule}





  
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


dimensions

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings.RateLimitDimension](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings-ratelimitdimension) <br/> _REQUIRED_ <br/> A list of dimensions that are to be applied for this rate limit configuration.
Order matters as the dimensions are processed sequentially and the descriptor
is composed by appending descriptor entries in that sequence.
If the condition for a dimension is not satisfied and cannot append a descriptor entry,
no descriptor list is generated for the entire setting.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## HTTPRewrite {#tetrateio-api-tsb-gateway-v2-httprewrite}

Configuration for an URL rewrite rule.



  
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


uri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Rewrite the path (or the prefix) portion of the URI with this value. If the original URI was
matched based on prefix, the value provided in this field will replace the corresponding
matched prefix.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authority

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Rewrite the Authority/Host header with this value.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Headers {#tetrateio-api-tsb-gateway-v2-headers}

Header manipulation rules.



  
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


request

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Headers.HeaderOperations](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-headers-headeroperations) <br/> Header manipulation rules to apply before forwarding a request to the destination service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


response

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Headers.HeaderOperations](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-headers-headeroperations) <br/> Header manipulation rules to apply before returning a response to the caller.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### HeaderOperations {#tetrateio-api-tsb-gateway-v2-headers-headeroperations}

HeaderOperations Describes the header manipulations to apply.



  
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


set

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Overwrite the headers specified by key with the given values.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


add

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Append the given values to the headers specified by keys (will create a comma-separated list
of values).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


remove

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Remove a the specified headers.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HostsReachability {#tetrateio-api-tsb-gateway-v2-hostsreachability}

`HostsReachability` defines the list of gateway hosts that this workspace can reach.
In multicluster deployments, hosts are reachable to all namespaces(`*`) by default.
However, this may not always be necessary, as clients may only be present in a few namespaces.
By configuring this, a list of namespaces can be limited to the namespaces configured in the workspace.
Workspaces with no hosts reachability configuration are considered to have reachable to all hosts.



  
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


hostnames

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch) <br/> _REQUIRED_ <br/> The Gateway hostname that can be one of the following. Hostnames should match hosts configured in the Gateway.

- Exact hostnames.
For example, `echo.tetrate.io`.

- Prefix hostnames.
For example, `echo`. Hosts starting with `echo` are considered.

- Regex hostnames.
For example, `^echo.*io$`. Hosts starting with `echo` and ending with `io` are considered.

- List can be empty `[]`.
Workspaces with explicitly empty hostnames are considered to not want to see any hosts.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HttpMatchCondition {#tetrateio-api-tsb-gateway-v2-httpmatchcondition}

A single match clause to match all aspects of a request.



  
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


uri

</td>

<td>

[tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch) <br/> URI to match.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


headers

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch)> <br/> The header keys must be lowercase and use hyphen as the separator, e.g. x-request-id.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HttpModifyAction {#tetrateio-api-tsb-gateway-v2-httpmodifyaction}

HTTP path/url/header modification.



  
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


rewrite

</td>

<td>

[tetrateio.api.tsb.gateway.v2.HTTPRewrite](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-httprewrite) <br/> Rewrite the HTTP Host or URL or both.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


headers

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Headers](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-headers) <br/> Add/remove/overwrite one or more HTTP headers in a request or response.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## RateLimitSettings {#tetrateio-api-tsb-gateway-v2-ratelimitsettings}

Configuration for ratelimiting HTTP/gRPC requests
This has a list of rate limit rules that can be configured.
With each rule a list of dimensions can be defined.
A request counts towards the limit if all of the dimensions match the
attributes of the request.
When the matched requests exceed the limit, a 429 response is returned.



  
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


rules

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.RateLimitSettings.RateLimitRule](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitrule) <br/> _REQUIRED_ <br/> A list of rules for ratelimiting.
Each rule defines a list of dimensions to match on and the rate limit value
for the rule. Each rule is independant of the other.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


failClosed

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If the rate limit service is unavailable, the request will fail
if failClosed is set to true. Defaults to false.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


timeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The timeout in seconds for the rate limit server RPC.
Defaults to 0.020 seconds (20ms).
Traffic will not be allowed to the destination if failClosed is set to true
and the request to the rate limit server times out.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### RateLimitDimension {#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitdimension}

RateLimitDimension is a condition to match HTTP requests
that should be rate limited.



  
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


remoteAddress

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimitSettings.RateLimitDimension.RemoteAddress](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitdimension-remoteaddress) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on the remote address of client.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


header

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimitSettings.RateLimitDimension.Header](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitdimension-header) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> dimension_specifier</sup>_ <br/> Rate limit on certain HTTP headers.
Special header names such as `:path` and `:method` can also be used.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### Header {#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitdimension-header}

RateLimit based on certain headers



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the header to match on.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch) <br/> Value of the header to match on if matching on a specific value.
If not specified, ratelimit on every unique value of the header.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### RemoteAddress {#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitdimension-remoteaddress}

RateLimit based on the client's remote address, extracted from
the trusted X-Forwarded-For header.



  
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


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Ratelimit on a specific remote address.
If the value is set to "*", ratelimit on
every unique remote address.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


### RateLimitRule {#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitrule}

RateLimitRule is the block to define each internal ratelimit configuration.



  
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


dimensions

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.RateLimitSettings.RateLimitDimension](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitdimension) <br/> _REQUIRED_ <br/> A list of dimensions to define each ratelimit rule.
Requests count towards the ratelimit value only when each and every
condition in a dimension is matched for a given HTTP request.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


limit

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimitSettings.RateLimitValue](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitvalue) <br/> _REQUIRED_ <br/> The ratelimit value that will be configured for the above rules.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


### RateLimitValue {#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitvalue}

RateLimitValue specifies the values that will be used
to determine the rate limit.



  
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


requestsPerUnit

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Specifies the value of the rate limit.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


unit

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimitSettings.RateLimitValue.Unit](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitvalue-unit) <br/> _REQUIRED_ <br/> Specifies the unit of time for rate limit.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## RateLimiting {#tetrateio-api-tsb-gateway-v2-ratelimiting}

Configuration for ratelimiting
HTTP/gRPC requests can be rate limited based on a variety of
attributes in the request such as headers (including cookies), URL
path/prefixes, client remote address etc.



  
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


settings

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimitSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimitsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> ratelimit_specifier</sup>_ <br/> Use Envoy and TSB's rateLimit server for ratelimiting HTTP Requests

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


externalService

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ExternalRateLimitServiceSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-externalratelimitservicesettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> ratelimit_specifier</sup>_ <br/> Configure ratelimiting using an external ratelimit server.
This configuration only configures Envoy's ratelimit filters
The user is expected to provision and configure their
own external ratelimit server with the appropriate ratelimit
values

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Redirect {#tetrateio-api-tsb-gateway-v2-redirect}





  
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


uri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> On a redirect, overwrite the Path portion of the URL with this value.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authority

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> On a redirect, overwrite the Authority/Host portion of the URL with this value.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


redirectCode

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> On a redirect, Specifies the HTTP status code to use in the redirect
response. It is expected to be 3XX. The default response code is MOVED_PERMANENTLY (301).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> On a redirect, overwrite the Port portion of the URL with this value

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scheme

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> On a redirect, overwrite the scheme with this one. This can be used
to perform http -> https redirect by setting this to "https". Currently,
the only supported values are "http" and "https" (in lower-case).

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ServerTLSSettings {#tetrateio-api-tsb-gateway-v2-servertlssettings}





  
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


mode

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings.TLSMode](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings-tlsmode) <br/> Set this to SIMPLE, or MUTUAL for one-way TLS, mutual TLS
respectively.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


secretName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the secret in Kubernetes that holds the TLS certs
including the CA certificates. The secret (type generic) should
contain the following keys and values: key: `<privateKey>`, cert:
`<serverCert>`, cacert: `<CACertificate>`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


files

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings.FileSource](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings-filesource) <br/> Load the keys and certificates from
files accessible to the ingress gateway workload.
Only one of secretName or files must be specified.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


minProtocolVersion

</td>

<td>

[tetrateio.api.tsb.gateway.v2.TLSProtocol](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-tlsprotocol) <br/> Set the minimum supported TLS protocol version.
Valid options: TLS_AUTO, TLSV1_0, TLSV1_1, TLSV1_2, TLSV1_3.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


maxProtocolVersion

</td>

<td>

[tetrateio.api.tsb.gateway.v2.TLSProtocol](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-tlsprotocol) <br/> Set the maximum supported TLS protocol version.
Valid options: TLS_AUTO, TLSV1_0, TLSV1_1, TLSV1_2, TLSV1_3.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


cipherSuites

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of cipher suites to be used for TLS connections.
Examples of cipher suites:
- "TLS_RSA_WITH_AES_256_CBC_SHA"
- "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
- "TLS_DHE_RSA_WITH_AES_256_GCM_SHA384"
- "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
- "TLS_RSA_WITH_3DES_EDE_CBC_SHA"

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subjectAltNames

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of Subject Alternative Names (SAN) from the client's certificate that are accepted
for client identity verification during the TLS handshake.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### FileSource {#tetrateio-api-tsb-gateway-v2-servertlssettings-filesource}

File path configuration of TLS keys and certificates.



  
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


serverCertificate

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The path to the server cert file

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


privateKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The path to the server private key file

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


caCertificates

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The path to the file containing ca certs for verifying clients while using mutual TLS

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## StringMatch {#tetrateio-api-tsb-gateway-v2-stringmatch}

Describes how to match a given string in HTTP headers. Match is case-sensitive.



  
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


exact

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> match_type</sup>_ <br/> Exact string match.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


prefix

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> match_type</sup>_ <br/> Prefix-based match.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


regex

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> match_type</sup>_ <br/> ECMAscript style regex-based match.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




#### Unit {#tetrateio-api-tsb-gateway-v2-ratelimitsettings-ratelimitvalue-unit}

Units of time.


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


UNKNOWN

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SECOND

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


MINUTE

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


HOUR

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


DAY

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
</table>
  



### TLSMode {#tetrateio-api-tsb-gateway-v2-servertlssettings-tlsmode}




<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


DISABLED

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SIMPLE

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


MUTUAL

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
</table>
  



## TLSProtocol {#tetrateio-api-tsb-gateway-v2-tlsprotocol}

Enumeration for TLS protocol versions.


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


TLS_AUTO

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSV1_0

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSV1_1

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSV1_2

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSV1_3

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
</table>
  



---
title: Transport layer security config
description: Specifies configuration of a TLS client.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Transport layer security config specifies configuration of a TLS client.





## ClientTransportSecurity {#tetrateio-api-onboarding-config-types-config-v1alpha1-clienttransportsecurity}

ClientTransportSecurity specifies transport layer security configuration.



  
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


tls

</td>

<td>

[tetrateio.api.onboarding.config.types.config.v1alpha1.TlsClient](../../../../../onboarding/config/types/config/v1alpha1/transport_security#tetrateio-api-onboarding-config-types-config-v1alpha1-tlsclient) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> TLS client configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


none

</td>

<td>

[tetrateio.api.onboarding.config.types.config.v1alpha1.PlainTextClient](../../../../../onboarding/config/types/config/v1alpha1/transport_security#tetrateio-api-onboarding-config-types-config-v1alpha1-plaintextclient) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Plain-text client configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TlsClient {#tetrateio-api-onboarding-config-types-config-v1alpha1-tlsclient}

TlsClient specifies configuration of a TLS client.



  
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


sni

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> SNI string to present to the server during TLS handshake instead of the
default value (host address).

Defaults to empty string, in which case the default SNI value (host
address) will be used.

This setting is meant for use in non-production scenarios, such as:

1. when the server is not reachable by a DNS name (e.g., because user has
   no means to create a DNS record)

2. when the server is only reachable by a DNS name different from the name
   TLS certificate was issued for

When set to a non-empty string, TLS client will validate certificate
presented by the server against the SNI value rather than host address.

TODO(yaro): add [(validate.rules).string = { address: true, ignore_empty: true } ]

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


insecureSkipVerify

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> once `protoc-gen-validate` tool is updated up to 0.5.0+
            that support `ignore_empty` option
When set to `true`, TLS client will not verify validity of the server
certificate (:warning:).

Defaults to `false`.

:warning: `WARNING`: This setting makes TLS connections insecure because
   client does not validate identity of the server and might end up sending
   security-sensitive information to an attacker (man-in-the-middle).

:warning: `NEVER` use this setting in production scenarios!

This setting is meant for use in non-production scenarios, such as:

1. getting started guides

2. disposable test and demo environments

3. local development environments

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




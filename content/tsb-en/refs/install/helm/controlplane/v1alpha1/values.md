---
title: install/helm/controlplane/v1alpha1/values.proto
description: install/helm/controlplane/v1alpha1/values.proto
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->







## Secrets {#tetrateio-api-install-helm-controlplane-v1alpha1-secrets}

Secrets available in the ControlPlane installation.



  
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


tsb

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Secrets.TSB](../../../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-tsb) <br/> Secrets to reach the TSB Management Plane.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


elasticsearch

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Secrets.ElasticSearch](../../../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-elasticsearch) <br/> Secrets to reach the Elasticsearch.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xcp

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Secrets.XCP](../../../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-xcp) <br/> Secrets to reach the XCP Central in the Management Plane.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusterServiceAccount

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Secrets.ClusterServiceAccount](../../../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-clusterserviceaccount) <br/> Cluster service account used to authenticate to the Management Plane.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ClusterServiceAccount {#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-clusterserviceaccount}

Cluster service account used to authenticate to the Management Plane.



  
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


clusterFQN

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> TSB FQN of the onboarded cluster resource. This will be generate tokens for all Control Plane agents.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


JWK

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Literal JWK used to generate and sign the tokens for all the Control Plane agents.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


encodedJWK

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Base64-encoded JWK used to generate and sign the tokens for all the Control Plane agents.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ElasticSearch {#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-elasticsearch}

Secrets to reach the Elasticsearch.



  
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


username

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The username to access Elasticsearch.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


password

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The password to access Elasticsearch.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cacert

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Elasticsearch CA cert TLS used by control plane to verify TLS connection.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### TSB {#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-tsb}

Secrets to reach the TSB Management Plane.



  
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


cacert

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> CA certificate used to verify TLS certs exposed the Management Plane (front envoy).

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### XCP {#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-xcp}

Secrets to reach the XCP Central in the Management Plane.



  
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


autoGenerateCerts

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Enabling this will auto generate XCP Edge certificate if mTLS is enabled to authenticate to XCP Central. Requires cert-manager.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rootca

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> CA certificate of XCP components.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rootcakey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Key of the CA certificate of XCP components.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


edge

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Secrets.XCP.Edge](../../../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-xcp-edge) <br/> Secrets for the XCP Edge component.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### Edge {#tetrateio-api-install-helm-controlplane-v1alpha1-secrets-xcp-edge}

Secrets for the XCP Edge component.



  
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


cert

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Edge certificate used for mTLS with XCP Central.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


key

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Key of the Edge certificate used for mTLS with XCP Central.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


token

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> JWT token used to authenticate XCP Edge against the XCP Central.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Values {#tetrateio-api-install-helm-controlplane-v1alpha1-values}

Values available for the TSB Control Plane chart.
This is an alpha API, so future versions could include breaking changes.



  
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


image

</td>

<td>

[tetrateio.api.install.helm.common.v1alpha1.Image](../../../../install/helm/common/v1alpha1/common#tetrateio-api-install-helm-common-v1alpha1-image) <br/> Values for the TSB operator image.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


spec

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.ControlPlaneSpec](../../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-controlplanespec) <br/> Values for the Control Plane CR spec.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


secrets

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Secrets](../../../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-secrets) <br/> Values for the Control Plane secrets.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


operator

</td>

<td>

[tetrateio.api.install.helm.common.v1alpha1.Operator](../../../../install/helm/common/v1alpha1/common#tetrateio-api-install-helm-common-v1alpha1-operator) <br/> Values for the TSB operator application.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




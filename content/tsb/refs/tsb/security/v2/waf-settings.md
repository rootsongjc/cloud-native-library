---
title: WAF Settings
description: Settings for the Web Application Firewall component, based on the Modsecurity/Coraza Seclang.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

The following example creates a security group for the sidecars in `ns1`,
`ns2` and `ns3` namespaces owned by its parent workspace `w1` under tenant
`mycompany`, and a security setting that applies the WAF Settings. And the
security group and security settings to which this WAF Settings is applied to.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
---
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  waf:
    rules:
      - Include @recommended-conf
```

In the following examples, the security rule for blocking XSS requests is
enabled on `Tier1Gateway` and `IngressGateway` respectively, with an ad-hoc
debug configuration, instead of the one defined in the security rule.

```yaml
apiVersion: gateway.xcp.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-waf-gw
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  passthroughServers:
  - name: nginx
    port: 8443
    hostname: nginx.example.com
  waf:
    rules:
      - Include @owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf
```

```yaml
apiVersion: gateway.xcp.tetrate.io/v2
kind: IngressGateway
metadata:
  name: waf-gw
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: waf-gateway
  waf:
    rules:
      - SecRuleEngine DETECTION_ONLY
      - SecDebugLogLevel 5
      - Include @owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf
  http:
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
```





## WAFSettings {#tetrateio-api-tsb-security-v2-wafsettings}

WAFSettings configure WAF based on seclang
See https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v3.x%29#Configuration_Directives



  
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

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Rules to be leveraged by WAF. The parser evaluates the list of rules from the top to the bottom.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  




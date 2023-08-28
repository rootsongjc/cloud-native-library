---
title: Using WAF Capabilities
description: Shows how to configure and enable WAF capabilities
weight: 7
---

:::warning Technical Preview
Tetrate WAF is a technical preview of a future capability of TSB. It is not recommended for production usage at this stage.
:::

This document will describe how Web Application Firewall (WAF) capabilities can be enabled and configured in TSB.

## Overview
A Web Application Firewall (WAF) inspects inbound and outbound HTTP traffic. It matches the traffic against a range of signatures in order to detect attack attempts, malformed traffic, and exfiltration of sensitive data. Suspicious traffic can be blocked, alerts can be raised, and traffic can be logged for later analysis.

Traditional WAF solutions operate at the edge of a network, inspecting ingress and egress traffic to and from the Internet. They operate on the assumption that a bad actor is external to your internal infrastructure.

Tetrate WAF runs within an application, protecting individual services in a very granular way. With Tetrate WAF, you can enhance your [zero trust](../concepts/security) posture by protecting from internal and external attackers alike.

Benefits from enabling this feature include:
- Detection and blocking of attack traffic and data exfiltration using the industry-standard [OWASP Core Rule Set](https://coreruleset.org/) (CRS) detection rules. At the time of writing, Tetrate WAF uses CRS [v4.0.0-rc1](https://github.com/coreruleset/coreruleset/releases/tag/v4.0.0-rc1).
- Fine-tuning of protection with tailored custom rules.
- The ability to quickly mitigate attacks against known CVEs or 0days.
- Flexible deployment based on your infrastructure and known vulnerable workloads.

## WAF in TSB
Components that can be configured with WAF capabilities: [Organization](../refs/tsb/v2/organization), [Tenant](../refs/tsb/v2/tenant), [Workspace](../refs/tsb/v2/workspace), [SecurityGroup](../refs/tsb/security/v2/security_group), [IngressGateway](../refs/tsb/gateway/v2/ingress_gateway), [EgressGateway](../refs/tsb/gateway/v2/egress_gateway), and [Tier1Gateway](../refs/tsb/gateway/v2/tier1_gateway).
WAF feature can be specified in the [`defaultSecuritySettings`](../refs/tsb/security/v2/security_setting) property of [OrganizationSetting](../refs/tsb/v2/organization_setting), [TenantSetting](../refs/tsb/v2/tenant_setting), [WorkspaceSetting](../refs/tsb/v2/workspace_setting), and in the `spec` of [SecuritySettings](../refs/tsb/security/v2/security_setting).

```yaml
  waf:
    rules:
      - Include @recommended-conf       # Basic WAF setup
      - Include @crs-setup-conf         # Core Rule Set setup
      - Include @owasp_crs/*.conf       # Load the Core Rule Set rules
```

As shown in the snippet above, WAF rules are based on the [Seclang language](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v3.x%29#Configuration_Directives). Including the following aliases you can easily enable common configurations and rules:
- `@recommended-conf`: Basic WAF setup. The complete file for further details can be found [here](https://github.com/tetrateio/coraza-proxy-wasm/blob/main/wasmplugin/rules/coraza.conf-recommended.conf). This configuration includes:
    - WAF engine mode: `DetectionOnly`. Traffic is inspected and logs are generated. No disruptive actions are performed. It is the suggested way to evaluate and fine-tune the WAF minimizing unexpected behaviors.
    - Request body access: `On`. Allows inspection of request bodies, including POST parameters.
    - Response body access: `On`. Allows inspection of response bodies.
- `@crs-setup-conf`: Basic CRS configuration. It assumes that engine WAF settings have already been loaded (e.g. via `@recommended-conf`). The complete file for further details can be found [here](https://github.com/tetrateio/coraza-proxy-wasm/blob/main/wasmplugin/rules/crs-setup.conf.example). This configuration includes:
    - Mode of Operation: `Anomaly Scoring Mode`
    - Paranoia level: `PL1` (least number of false positives).
- `@owasp_crs`: alias of the main CRS folder containing the rules files. Folder organization and filename convention stick with the official CRS repository. Details can be found [here](https://github.com/coreruleset/coreruleset/tree/v4.0.0-rc1/rules).

## Example
Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../concepts/toc). <br />
✓ Install the TSB environment. You can use [TSB demo](../setup/self_managed/demo-installation) for quick install. <br />
✓ Completed TSB [quickstart](../quickstart). This document assumes you already created a Tenant and are familiar with Workspace and Config Groups. Also, you need to configure tctl to your TSB environment.

In this example, `httpbin` will be used as the workload. Requests that come to Ingress GW will be filtered by the WAF and denied if malicious attacks are detected. 

### Deploy `httpbin` Service

Follow [all of the instructions in this document](../reference/samples/httpbin) to create the `httpbin` service.

Next commands will assume you have an Organization=`tetrate`, Tenant=`tetrate`, Workspace=`httpbin`, GatewayGroup=`httpbin-gateway`.

### Enable the WAF

Create a file named `waf-ingress-gateway.yaml` containing the definition of the [IngressGateway](../refs/tsb/gateway/v2/ingress_gateway):

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-gw
  group: httpbin-gateway
  workspace: httpbin
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: httpbin
    labels:
      app: httpbin-ingress-gateway
  http:
    - name: httpbin
      port: 443
      hostname: "httpbin.tetrate.io"
      routing:
        rules:
          - route:
              host: "httpbin/httpbin.httpbin.svc.cluster.local"
  waf:
    rules:
      - Include @recommended-conf  # Basic WAF setup
      - SecRuleEngine On           # Override rule engine mode in @recommended-conf enabling WAF intervention
      - Include @crs-setup-conf    # Initialize the CRS
      - Include @owasp_crs/*.conf  # Load the CRS rules
```
:::note
Keep in mind that rules' order matters: rules are checked in the order they are listed under `rules`. It is expected to have main WAF settings, followed by CRS setup, followed by CRS rules. 
:::

Apply it on TSB:
```
tctl apply -f waf-ingress-gateway.yaml
```

## Test it
You should now be able to send requests to the Ingress Gateway.
```
export GATEWAY_IP=$(kubectl -n httpbin get service httpbin-ingress-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```
Sending a true negative request:
```
curl 'http://httpbin.tetrate.io:443?arg=argument_1' -kI --connect-to httpbin.tetrate.io:443:$GATEWAY_IP:443
```
You should see a `200 OK` response code similar to this:
```
HTTP/1.1 200 OK
server: istio-envoy
date: Wed, 30 Nov 2022 15:20:28 GMT
content-type: text/html; charset=utf-8
content-length: 9593
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 4
```
While sending a true positive request (potential malicious Cross-Site Scripting attempt):
```
curl 'http://httpbin.tetrate.io:443?arg=<script>alert('0')</script>' -kI --connect-to httpbin.tetrate.io:443:$GATEWAY_IP:443
```
You should see the request denied with a `403 Forbidden` error. It proves that the WAF detected the malicious pattern and interrupted the connection:
```
HTTP/1.1 403 Forbidden
date: Wed, 30 Nov 2022 15:33:30 GMT
server: istio-envoy
transfer-encoding: chunked
```
You may take a look at the Envoy logs, in which also the WAF logs reside, for further details about the detection:
```
export GATEWAY_POD=$(kubectl get pods -n httpbin -o jsonpath="{.items[1].metadata.name}")
kubectl logs -n httpbin $GATEWAY_POD | tail -n 10 | grep "Coraza:"
```
You will see an output log similar to the following one:
```
2022-11-30T15:33:30.032506Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. XSS Attack Detected via libinjection [file "@owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "0"] [id "941100"] [rev ""] [msg "XSS Attack Detected via libinjection"] [data "Matched Data: XSS data found within ARGS:arg: <script>alert(0)</script>"] [severity "critical"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "paranoia-level/1"] [tag "OWASP_CRS"] [tag "capec/1000/152/242"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]

2022-11-30T15:33:30.032829Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. XSS Filter - Category 1: Script Tag Vector [file "@owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "0"] [id "941110"] [rev ""] [msg "XSS Filter - Category 1: Script Tag Vector"] [data "Matched Data: <script> found within ARGS:arg: <script>alert(0)</script>"] [severity "critical"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "paranoia-level/1"] [tag "OWASP_CRS"] [tag "capec/1000/152/242"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]

2022-11-30T15:33:30.035356Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. NoScript XSS InjectionChecker: HTML Injection [file "@owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "0"] [id "941160"] [rev ""] [msg "NoScript XSS InjectionChecker: HTML Injection"] [data "Matched Data: <script found within ARGS:arg: <script>alert(0)</script>"] [severity "critical"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "paranoia-level/1"] [tag "OWASP_CRS"] [tag "capec/1000/152/242"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]

2022-11-30T15:33:30.036527Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. Inbound Anomaly Score Exceeded (Total Score: 15) [file "@owasp_crs/REQUEST-949-BLOCKING-EVALUATION.conf"] [line "0"] [id "949110"] [rev ""] [msg "Inbound Anomaly Score Exceeded (Total Score: 15)"] [data ""] [severity "emergency"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "anomaly-evaluation"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]
```
Each log line shows details about a rule that has been triggered specifying the category of the attack and the relative matched data. 

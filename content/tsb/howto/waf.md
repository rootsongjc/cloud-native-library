---
title: 使用 WAF 功能
description: 展示如何配置和启用 WAF 功能
weight: 7
---

{{<callout warning 技术预览>}}
Tetrate WAF 是 TSB 未来功能的技术预览。目前不建议在生产环境中使用。
{{</callout>}}

本文将描述如何在 TSB 中启用和配置 Web 应用程序防火墙（WAF）功能。

## 概述
Web 应用程序防火墙（WAF）检查入站和出站的 HTTP 流量。它会将流量与一系列签名进行匹配，以检测攻击尝试、格式不正确的流量和敏感数据的泄漏。可疑的流量可以被阻止，警报可以被触发，并且流量可以被记录以供后续分析。

传统的 WAF 解决方案在网络的边缘运行，检查从互联网进出的流量。它们基于这样的假设：恶意行为者是外部的，不在你的内部基础设施中。

Tetrate WAF 在应用程序内部运行，以非常精细的方式保护个别服务。通过 Tetrate WAF，你可以增强你的[零信任](../../concepts/security)姿态，保护内部和外部攻击者。

启用此功能的好处包括：
- 使用行业标准的 [OWASP 核心规则集](https://coreruleset.org/)（CRS）检测规则来检测攻击流量和数据泄漏的检测和阻止。在撰写本文时，Tetrate WAF 使用 CRS [v4.0.0-rc1](https://github.com/coreruleset/coreruleset/releases/tag/v4.0.0-rc1)。
- 使用定制的自定义规则进行保护的微调。
- 快速应对已知 CVE 或 0day 攻击的能力。
- 基于你的基础设施和已知的易受攻击工作负载的灵活部署。

## TSB 中的 WAF
可以配置 WAF 功能的组件包括：[组织](../../refs/tsb/v2/organization)、[租户](../../refs/tsb/v2/tenant)、[工作区](../../refs/tsb/v2/workspace)、[安全组](../../refs/tsb/security/v2/security-group)、[入口网关](../../refs/tsb/gateway/v2/ingress-gateway)、[出口网关](../../refs/tsb/gateway/v2/egress-gateway) 和 [Tier1 网关](../../refs/tsb/gateway/v2/tier1-gateway)。WAF 功能可以在 [组织设置](../../refs/tsb/v2/organization-setting)、[租户设置](../../refs/tsb/v2/tenant-setting)、[工作区设置](../../refs/tsb/v2/workspace-setting) 的 [`defaultSecuritySettings`](../../refs/tsb/security/v2/security-setting) 属性中指定，以及在 [SecuritySettings](../../refs/tsb/security/v2/security-setting) 的 `spec` 中指定。

```yaml
  waf:
    rules:
      - Include @recommended-conf       # 基本 WAF 设置
      - Include @crs-setup-conf         # 核心规则集设置
      - Include @owasp_crs/*.conf       # 加载核心规则集规则
```

如上所示，WAF 规则基于 [Seclang 语言](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v3.x%29#Configuration_Directives)。包括以下别名，你可以轻松启用常见的配置和规则：
- `@recommended-conf`：基本 WAF 设置。有关更多详细信息，可以在[此处](https://github.com/tetrateio/coraza-proxy-wasm/blob/main/wasmplugin/rules/coraza.conf-recommended.conf)找到完整文件。此配置包括：
    - WAF 引擎模式：`DetectionOnly`。检查流量并生成日志。不执行破坏性操作。这是评估和微调 WAF 的建议方式，以最小化意外行为。
    - 请求正文访问：`On`。允许检查请求正文，包括 POST 参数。
    - 响应正文访问：`On`。允许检查响应正文。
- `@crs-setup-conf`：基本 CRS 配置。它假定引擎 WAF 设置已经加载（例如通过 `@recommended-conf`）。有关更多详细信息，可以在[此处](https://github.com/tetrateio/coraza-proxy-wasm/blob/main/wasmplugin/rules/crs-setup.conf.example)找到完整文件。此配置包括：
    - 操作模式：`异常得分模式`
    - 偏执级别：`PL1`（最低虚警数）。
- `@owasp_crs`：包含规则文件的主 CRS 文件夹的别名。文件夹组织和文件名约定与官方 CRS 存储库保持一致。有关详细信息，可以在[此处](https://github.com/coreruleset/coreruleset/tree/v4.0.0-rc1/rules)找到。
## 示例

在开始之前，请确保你已经：
- 熟悉 [TSB 概念](../../concepts/)。
- 安装 TSB 环境。你可以使用 [TSB 演示](../../setup/self-managed/demo-installation) 进行快速安装。
- 完成 TSB [快速入门](../../quickstart)。本文假定你已经创建了一个租户，并熟悉工作区和配置组。此外，你需要将 tctl 配置到你的 TSB 环境。

在本示例中，将使用 `httpbin` 作为工作负载。发送到 Ingress GW 的请求将经过 WAF 过滤，如果检测到恶意攻击，将被拒绝。

### 部署 `httpbin` 服务
请按照[此文档中的所有说明](../../reference/samples/httpbin)创建 `httpbin` 服务。

接下来的命令将假定你有一个组织=`tetrate`、租户=`tetrate`、工作区=`httpbin`、网关组=`httpbin-gateway`。

### 启用 WAF
创建一个名为 `waf-ingress-gateway.yaml` 的文件，其中包含 [IngressGateway](../../refs/tsb/gateway/v2/ingress-gateway) 的定义：

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
      - Include @recommended-conf  # 基本 WAF 设置
      - SecRuleEngine On           # 覆盖 @recommended-conf 中的规则引擎模式，启用 WAF 干预
      - Include @crs-setup-conf    # 初始化 CRS
      - Include @owasp_crs/*.conf  # 加载 CRS 规则
```
{{<callout note 注意>}}
规则的顺序很重要：规则按照它们在 `rules` 下列出的顺序进行检查。通常，主要的 WAF 设置首先出现，然后是 CRS 设置，然后是 CRS 规则。
{{</callout>}}

在 TSB 上应用它：
```
tctl apply -f waf-ingress-gateway.yaml
```

## 测试
现在，你应该能够发送请求到 Ingress Gateway。
```
export GATEWAY_IP=$(kubectl -n httpbin get service httpbin-ingress-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```
发送一个真正的负面请求：
```
curl 'http://httpbin.tetrate.io:443?arg=argument_1' -kI --connect-to httpbin.tetrate.io:443:$GATEWAY_IP:443
```
你应该会收到类似于以下内容的 `200 OK` 响应代码：
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
而对于真正的正面请求（潜在的恶意跨站脚本攻击）：
```
curl 'http://httpbin.tetrate.io:443?arg=<script>alert('0')</script>' -kI --connect-to httpbin.tetrate.io:443:$GATEWAY_IP:443
```
你应该会看到请求被拒绝，并显示 `403 Forbidden` 错误。这证明 WAF 检测到了恶意模式并中断了连接：
```
HTTP/1.1 403 Forbidden
date: Wed, 30 Nov 2022 15:33:30 GMT
server: istio-envoy
transfer-encoding: chunked
```
你可以查看 Envoy 日志，其中也包含 WAF 日志，以获取有关检测的更多详细信息：
```
export GATEWAY_POD=$(kubectl get pods -n httpbin -o jsonpath="{.items[1].metadata.name}")
kubectl logs -n httpbin $GATEWAY_POD | tail -n 10 | grep "Coraza:"
```
你将看到类似以下内容的输出日志：
```
2022-11-30T15:33:30.032506Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. XSS Attack Detected via libinjection [file "@owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "0"] [id "941100"] [rev ""] [msg "XSS Attack Detected via libinjection"] [data "Matched Data: XSS data found within ARGS:arg: <script>alert(0)</script>"] [severity "critical"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "paranoia-level/1"] [tag "OWASP_CRS"] [tag "capec/1000/152/242"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]

2022-11-30T15:33:30.032829Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. XSS Filter - Category 1: Script Tag Vector [file "@owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "0"] [id "941110"] [rev ""] [msg "XSS Filter - Category 1: Script Tag Vector"] [data "Matched Data: <script> found within ARGS:arg: <script>alert(0)</script>"] [severity "critical"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "paranoia-level/1"] [tag "OWASP_CRS"] [tag "capec/1000/152/242"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]

2022-11-30T15:33:30.035356Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. NoScript XSS InjectionChecker: HTML Injection [file "@owasp_crs/REQUEST-941-APPLICATION-ATTACK-XSS.conf"] [line "0"] [id "941160"] [rev ""] [msg "NoScript XSS InjectionChecker: HTML Injection"] [data "Matched Data: <script found within ARGS:arg: <script>alert(0)</script>"] [severity "critical"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-xss"] [tag "paranoia-level/1"] [tag "OWASP_CRS"] [tag "capec/1000/152/242"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]

2022-11-30T15:33:30.036527Z	critical	envoy wasm	wasm log httpbin.ingress-gw-tetrate-internal-waf-main0 ingress-gw-tetrate-internal-waf-main0: [client ""] Coraza: Warning. Inbound Anomaly Score Exceeded (Total Score: 15) [file "@owasp_crs/REQUEST-949-BLOCKING-EVALUATION.conf"] [line "0"] [id "949110"] [rev ""] [msg "Inbound Anomaly Score Exceeded (Total Score: 15)"] [data ""] [severity "emergency"] [ver "OWASP_CRS/4.0.0-rc1"] [maturity "0"] [accuracy "0"] [tag "anomaly-evaluation"] [hostname ""] [uri "/?arg=<script>alert(0)</script>"] [unique_id "nacXlZaiGUmkOTfLTaz"]
```

每条日志行显示一条被触发的规则的详细信息，指定攻击的类别和对应的匹配数据。

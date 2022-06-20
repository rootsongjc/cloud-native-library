::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <https://docs.cilium.io>
:::

Inspecting Network Flows with the CLI {#hubble_cli}
=====================================

This guide walks you through using the Hubble CLI to inspect network
flows and gain visibility into what is happening on the network level.

The best way to get help if you get stuck is to ask a question on the
[Cilium Slack channel](https://cilium.herokuapp.com). With Cilium
contributors across the globe, there is almost always someone available
to help.

::: {.tip}
::: {.title}
Tip
:::

This guide assumes that Cilium has been correctly installed in your
Kubernetes cluster and that Hubble has been enabled. Please see
`k8s_quick_install`{.interpreted-text role="ref"} and
`hubble_setup`{.interpreted-text role="ref"} for more information. If
unsure, run `cilium status` and validate that Cilium and Hubble are up
and running.
:::

::: {.note}
::: {.title}
Note
:::

This guide uses examples based on the Demo App. If you would like to run
them, deploy the Demo App first. Please refer to
`gs_http`{.interpreted-text role="ref"} for more details.
:::

Inspecting the cluster\'s network traffic with Hubble Relay
-----------------------------------------------------------

Let\'s issue some requests to emulate some traffic again. This first
request is allowed by the policy.

``` {.shell-session}
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
Ship landed
```

This next request is accessing an HTTP endpoint which is denied by
policy.

``` {.shell-session}
kubectl exec tiefighter -- curl -s -XPUT deathstar.default.svc.cluster.local/v1/exhaust-port
Access denied
```

Finally, this last request will hang because the `xwing` pod does not
have the `org=empire` label required by policy. Press Control-C to kill
the curl request, or wait for it to time out.

``` {.shell-session}
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
command terminated with exit code 28
```

Let\'s now inspect this traffic using the CLI. The command below filters
all traffic on the application layer (L7, HTTP) to the `deathstar` pod:

``` {.shell-session}
hubble observe --pod deathstar --protocol http
May  4 13:23:40.501: default/tiefighter:42690 -> default/deathstar-c74d84667-cx5kp:80 http-request FORWARDED (HTTP/1.1 POST http://deathstar.default.svc.cluster.local/v1/request-landing)
May  4 13:23:40.502: default/tiefighter:42690 <- default/deathstar-c74d84667-cx5kp:80 http-response FORWARDED (HTTP/1.1 200 0ms (POST http://deathstar.default.svc.cluster.local/v1/request-landing))
May  4 13:23:43.791: default/tiefighter:42742 -> default/deathstar-c74d84667-cx5kp:80 http-request DROPPED (HTTP/1.1 PUT http://deathstar.default.svc.cluster.local/v1/exhaust-port)
```

The following command shows all traffic to the `deathstar` pod that has
been dropped:

``` {.shell-session}
hubble observe --pod deathstar --verdict DROPPED
May  4 13:23:43.791: default/tiefighter:42742 -> default/deathstar-c74d84667-cx5kp:80 http-request DROPPED (HTTP/1.1 PUT http://deathstar.default.svc.cluster.local/v1/exhaust-port)
May  4 13:23:47.852: default/xwing:42818 <> default/deathstar-c74d84667-cx5kp:80 Policy denied DROPPED (TCP Flags: SYN)
May  4 13:23:47.852: default/xwing:42818 <> default/deathstar-c74d84667-cx5kp:80 Policy denied DROPPED (TCP Flags: SYN)
May  4 13:23:48.854: default/xwing:42818 <> default/deathstar-c74d84667-cx5kp:80 Policy denied DROPPED (TCP Flags: SYN)
```

Feel free to further inspect the traffic. To get help for the `observe`
command, use `hubble help observe`.

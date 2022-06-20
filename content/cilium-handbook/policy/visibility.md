---
weight: 2
title: 七层可视性
date: '2022-06-17T12:00:00+08:00'
type: book
---

虽然[监控](https://docs.cilium.io/en/stable/operations/troubleshooting/#monitor)数据路径状态提供对数据路径状态的自省，但默认情况下它只会提供对三层/四层数据包事件的可视性。如果配置了 [七层示例](https://docs.cilium.io/en/stable/policy/language/#l7-policy)，则可以查看七层协议，但这需要编写每个选定端点的完整策略。 为了在不配置完整策略的情况下获得对应用程序的更多可视性，Cilium 提供了一种在与 Kubernetes 一起运行时通过[注解](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)来规定可视性的方法。

可视性信息由注解中以逗号分隔的元组列表表示：

`<{Traffic Direction}/{L4 Port}/{L4 Protocol}/{L7 Protocol}>`

例如：

    <Egress/53/UDP/DNS>,<Egress/80/TCP/HTTP>

为此，你可以在 Kubernetes YAML 中或通过命令行提供注释，例如：

``` {.shell-session}
kubectl annotate pod foo -n bar io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Egress/80/TCP/HTTP>"
```

Cilium 将拾取 pod 已收到这些注释，并将透明地将流量重定向到代理，以便显示 `cilium monitor` 流量的输出被重定向到代理，例如：

    -> Request http from 1474 ([k8s:id=app2 k8s:io.kubernetes.pod.namespace=default k8s:appSecond=true k8s:io.cilium.k8s.policy.cluster=default k8s:io.cilium.k8s.policy.serviceaccount=app2-account k8s:zgroup=testapp]) to 244 ([k8s:io.cilium.k8s.policy.cluster=default k8s:io.cilium.k8s.policy.serviceaccount=app1-account k8s:io.kubernetes.pod.namespace=default k8s:zgroup=testapp k8s:id=app1]), identity 30162->42462, verdict Forwarded GET http://app1-service/ => 0
    -> Response http to 1474 ([k8s:zgroup=testapp k8s:id=app2 k8s:io.kubernetes.pod.namespace=default k8s:appSecond=true k8s:io.cilium.k8s.policy.cluster=default k8s:io.cilium.k8s.policy.serviceaccount=app2-account]) from 244 ([k8s:io.cilium.k8s.policy.serviceaccount=app1-account k8s:io.kubernetes.pod.namespace=default k8s:zgroup=testapp k8s:id=app1 k8s:io.cilium.k8s.policy.cluster=default]), identity 30162->42462, verdict Forwarded GET http://app1-service/ => 200

您可以通过检查该 pod 的 Cilium 端点来检查可视性策略的状态，例如：

``` bash
$ kubectl get cep -n kube-system
NAME                       ENDPOINT ID   IDENTITY ID   INGRESS ENFORCEMENT   EGRESS ENFORCEMENT   VISIBILITY POLICY   ENDPOINT STATE   IPV4           IPV6
coredns-7d7f5b7685-wvzwb   1959          104           false                 false                                    ready            10.16.75.193   f00d::a10:0:0:2c77
$
$ kubectl annotate pod -n kube-system coredns-7d7f5b7685-wvzwb io.cilium.proxy-visibility="<Egress/53/UDP/DNS>,<Egress/80/TCP/HTTP>" --overwrite
pod/coredns-7d7f5b7685-wvzwb annotated
$
$ kubectl get cep -n kube-system
NAME                       ENDPOINT ID   IDENTITY ID   INGRESS ENFORCEMENT   EGRESS ENFORCEMENT   VISIBILITY POLICY   ENDPOINT STATE   IPV4           IPV6
coredns-7d7f5b7685-wvzwb   1959          104           false                 false                OK                  ready            10.16.75.193   f00d::a10:0:0:2c7
```

## 故障排查

如果七层可视性未出现在 `cilium monitor` 或 Hubble 组件中，则值得仔细检查：

> - 没有在注解中指定的方向应用强制策略
> - CiliumEndpoint 中的 “可视性策略” 列显示 `OK`。如果为空，则未配置注解；如果显示错误，则可视性注解存在问题。

以下示例故意错误配置注解，以证明当可视性注解无法实现时，pod 的 CiliumEndpoint 会出现错误：

``` bash
$ kubectl annotate pod -n kube-system coredns-7d7f5b7685-wvzwb io.cilium.proxy-visibility="<Ingress/53/UDP/DNS>,<Egress/80/TCP/HTTP>"
pod/coredns-7d7f5b7685-wvzwb annotated
$
$ kubectl get cep -n kube-system
NAME                       ENDPOINT ID   IDENTITY ID   INGRESS ENFORCEMENT   EGRESS ENFORCEMENT   VISIBILITY POLICY                        ENDPOINT STATE   IPV4           IPV6
coredns-7d7f5b7685-wvzwb   1959          104           false                 false                dns not allowed with direction Ingress   ready            10.16.75.193   f00d::a10:0:0:2c77
```

## 限制

-   如果导入的规则选择了被注解的 pod，则可视性注解将不适用。
-   DNS 可视性仅在 egress 上可用。
-   不支持 Proxylib 解析器，包括 Kafka。要获得对这些协议的可视性，你必须创建一个允许所有七层流量的网络策略，方法是遵循 [七层示例](https://docs.cilium.io/en/stable/policy/language/#l7-policy)（[Kafka](https://docs.cilium.io/en/stable/policy/language/#kafka-policy)）或 [Envoy](https://docs.cilium.io/en/stable/concepts/security/proxy/envoy/#envoy) proxylib 扩展指南。此限制见 [GitHub Issue 14072](https://github.com/cilium/cilium/issues/14072)。

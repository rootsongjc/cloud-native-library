---
weight: 4
title: 故障排除
date: '2022-06-17T12:00:00+08:00'
type: book
---

## 策略规则到端点映射

确定哪些策略规则当前对端点有效，并且可以将来自  `cilium endpoint list` 和 `cilium endpoint get` 的数据与 `cilium policy get` 配对。`cilium endpoint get` 将列出适用于端点的每个规则的标签。可以传递标签列表给 `cilium policy get` 以显示确切的源策略。请注意，不能单独获取没有标签的规则（无标签会返回节点上的完整策略）。具有相同标签的规则将一起返回。

在下面的示例中，其中一个 `deathstar` pod 的端点 id 是 568。我们可以打印应用于它的所有策略：

``` bash
$ # Get a shell on the Cilium pod

$ kubectl exec -ti cilium-88k78 -n kube-system -- /bin/bash

$ # print out the ingress labels
$ # clean up the data
$ # fetch each policy via each set of labels
$ # (Note that while the structure is "...l4.ingress...", it reflects all L3, L4 and L7 policy.

$ cilium endpoint get 568 -o jsonpath='{range ..status.policy.realized.l4.ingress[*].derived-from-rules}{@}{"\n"}{end}'|tr -d '][' | xargs -I{} bash -c 'echo "Labels: {}"; cilium policy get {}'
Labels: k8s:io.cilium.k8s.policy.name=rule1 k8s:io.cilium.k8s.policy.namespace=default
[
  {
    "endpointSelector": {
      "matchLabels": {
        "any:class": "deathstar",
        "any:org": "empire",
        "k8s:io.kubernetes.pod.namespace": "default"
      }
    },
    "ingress": [
      {
        "fromEndpoints": [
          {
            "matchLabels": {
              "any:org": "empire",
              "k8s:io.kubernetes.pod.namespace": "default"
            }
          }
        ],
        "toPorts": [
          {
            "ports": [
              {
                "port": "80",
                "protocol": "TCP"
              }
            ],
            "rules": {
              "http": [
                {
                  "path": "/v1/request-landing",
                  "method": "POST"
                }
              ]
            }
          }
        ]
      }
    ],
    "labels": [
      {
        "key": "io.cilium.k8s.policy.name",
        "value": "rule1",
        "source": "k8s"
      },
      {
        "key": "io.cilium.k8s.policy.namespace",
        "value": "default",
        "source": "k8s"
      }
    ]
  }
]
Revision: 217


$ # repeat for egress
$ cilium endpoint get 568 -o jsonpath='{range ..status.policy.realized.l4.egress[*].derived-from-rules}{@}{"\n"}{end}' | tr -d '][' | xargs -I{} bash -c 'echo "Labels: {}"; cilium policy get {}'
```

`toFQDNs` 规则故障排除
-------------------------------

随着 DNS 数据的变化，在应用策略很长时间后，效果 `toFQDNs` 可能会发生变化。这会使调试意外阻塞的连接或瞬时故障变得困难。Cilium 提供 CLI 工具来内省在多个守护进程层中应用 FQDN 策略的状态：

1.  `cilium policy get` 应显示导入的 FQDN 策略：

    ``` json
    {
      "endpointSelector": {
        "matchLabels": {
          "any:class": "mediabot",
          "any:org": "empire",
          "k8s:io.kubernetes.pod.namespace": "default"
        }
      },
      "egress": [
        {
          "toFQDNs": [
            {
              "matchName": "api.twitter.com"
            }
          ]
        },
        {
          "toEndpoints": [
            {
              "matchLabels": {
                "k8s:io.kubernetes.pod.namespace": "kube-system",
                "k8s:k8s-app": "kube-dns"
              }
            }
          ],
          "toPorts": [
            {
              "ports": [
                {
                  "port": "53",
                  "protocol": "ANY"
                }
              ],
              "rules": {
                "dns": [
                  {
                    "matchPattern": "*"
                  }
                ]
              }
            }
          ]
        }
      ],
      "labels": [
        {
          "key": "io.cilium.k8s.policy.derived-from",
          "value": "CiliumNetworkPolicy",
          "source": "k8s"
        },
        {
          "key": "io.cilium.k8s.policy.name",
          "value": "fqdn",
          "source": "k8s"
        },
        {
          "key": "io.cilium.k8s.policy.namespace",
          "value": "default",
          "source": "k8s"
        },
        {
          "key": "io.cilium.k8s.policy.uid",
          "value": "fc9d6022-2ffa-4f72-b59e-b9067c3cfecf",
          "source": "k8s"
        }
      ]
    }
    ```

2.  发出 DNS 请求后，应通过以下方式获得 FQDN 到 IP 的映射：`cilium fqdn cache list`
    
    ``` bash
    # cilium fqdn cache list
    Endpoint   FQDN                TTL      ExpirationTime             IPs
    2761       help.twitter.com.   604800   2019-07-16T17:57:38.179Z   104.244.42.67,104.244.42.195,104.244.42.3,104.244.42.131
    2761       api.twitter.com.    604800   2019-07-16T18:11:38.627Z   104.244.42.194,104.244.42.130,104.244.42.66,104.244.42.2
    ```
    
3.  如果允许流量，则这些 IP 应通过以下方式具有相应的本地身份：`cilium identity list | grep <IP>`
    
    ``` bash
    # cilium identity list | grep -A 1 104.244.42.194
    16777220   cidr:104.244.42.194/32
               reserved:world
    ```

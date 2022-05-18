---
weight: 120
title: Istio 生态
date: '2022-05-18T00:00:00+08:00'
type: book
icon: book-open
icon-pack: fas
---

Istio 服务网格自 2017 年 5 月开源以来，已围绕其周边诞生了诸多开源项目，这些项目有的是对 Istio 本身的扩展，有的是可以与 Istio 集成，还有的是 Istio 周边的开源工具。

本章将分门别类为读者介绍 Istio 生态中的开源项目，以帮助读者对 Istio 的开源生态有个更直观的了解，另一方面也可以作为读者个人的选型参考。

## Istio 周边开源项目

下表中列举 Istio 生态中的开源项目，按照开源时间排序。

| 项目名称                                                     | 开源时间      | 类别     | 描述                                                   | 主导公司   | Star 数量 | 与 Istio 的关系                               |
| ------------------------------------------------------------ | ------------- | -------- | ------------------------------------------------------ | ---------- | --------- | --------------------------------------------- |
| [Envoy](https://github.com/envoyproxy/envoy)                 | 2016年 9 月   | 网络代理 | 云原生高性能边缘/中间服务代理                          | Lyft       | 18300     | 默认的数据平面                                |
| [Istio](https://github.com/istio/istio/)                     | 2017 年 5 月  | 服务网格 | 连接、保护、控制和观察服务。                           | Google     | 28400     | 控制平面                                      |
| [Emissary Gateway](https://github.com/emissary-ingress/emissary) | 2018 年 2 月  | 网关     | 用于微服务的 Kubernetes 原生 API 网关，基于 Envoy 构建 | Ambassador | 3500      | 可连接 Istio                                  |
| [APISIX](https://github.com/apache/apisix)                   | 2019 年 6 月  | 网关     | 云原生 API 网关                                        | API7       | 7400      | 可作为 Istio 的数据平面运行也可以单独作为网关 |
| [MOSN](https://github.com/mosn/mosn)                         | 2019 年 12 月 | 代理     | 云原生边缘网关及代理                                   | 蚂蚁       | 3400      | 可作为 Istio 数据平面                         |
| [Slime](https://github.com/slime-io/slime)                   | 2021 年 1月   | 扩展     | 基于 Istio 的智能服务网格管理器                        | 网易       | 204       | 为 Istio 增加一个管理平面                     |
| [GetMesh](https://github.com/tetratelabs/getmesh)            | 2021 年 2 月  | 工具     | Istio 集成和命令行管理工具                             | Tetrate    | 91        | 实用工具，可用于 Istio 多版本管理             |
| [Aeraki](https://github.com/aeraki-framework/aeraki)         | 2021 年 3 月  | 扩展     | 管理 Istio 的任何七层负载                              | 腾讯       | 280       | 扩展多协议支持                                |
| [Layotto](https://github.com/mosn/layotto/)                  | 2021 年 6 月  | 运行时   | 云原生应用运行时                                       | 蚂蚁       | 325       | 可以作为 Istio 的数据平面                     |
| [Hango Gateway](https://github.com/hango-io/hango-gateway)   | 2021 年 8 月  | 网关     | 基于 Envoy 和 Istio 构建的 API 网关                    | 网易       | 187       | 可与 Istio 集成                               |

**注意**

1. 开源时间以 GitHub 仓库创建时间为准
2. Star 数量统计截止时间为 2021年11月11 日

## 参考

- [Building Ambassador, an Open Source API Gateway on Kubernetes and Envoy - blog.ambassador.io](https://medium.com/@datawire/building-ambassador-an-open-source-api-gateway-on-kubernetes-and-envoy-33637a9fa6f8)
- [蚂蚁开源多运行时项目 Layotto 简介 - cloudnative.to](https://cloudnative.to/blog/mosn-layotto-intro/)
- [Slime：让 Istio 服务网格变得更加高效与智能 - cloudnative.to](https://cloudnative.to/blog/netease-slime/)
- [使用 Aeraki 在 Isito 中支持 Dubbo、 Thrift、 Redis，以及任何七层协议 - cloudnative.to](https://cloudnative.to/blog/istiocon-layer7-traffic)
- [Apache APISIX 的全流量 API 网关统筹集群流量 - cloudnative.to](https://cloudnative.to/blog/full-traffic-api-gateway-based-on-apache-apisix/)
- [GetMesh 官网 - istio.tetratelabs.io](https://istio.tetratelabs.io/zh/)
- [MOSN 官网 - mosn.io](https://mosn.io)
- [Istio 官网 - istio.io](https://istio.io)
- [Envoy 官网 - envoyproxy.io](https://envoyproxy.io)

{{< cta cta_text="阅读本章" cta_link="aeraki" >}}
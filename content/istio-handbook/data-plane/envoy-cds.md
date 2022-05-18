---
weight: 60
title: CDS（集群发现服务）
date: '2022-05-18T00:00:00+08:00'
type: book
---

# CDS（集群发现服务）

集群发现服务（CDS）是一个可选的 API，Envoy 将调用该 API 来动态获取集群管理器的成员。Envoy 还将根据 API 响应协调集群管理，根据需要完成添加、修改或删除已知的集群。

关于 Envoy 是如何通过 CDS 从 `pilot-discovery` 服务中获取的 cluster 配置，请参考 [Service Mesh深度学习系列part3—istio源码分析之pilot-discovery模块分析（续）](https://cloudnative.to/blog/istio-service-mesh-source-code-pilot-discovery-module-deepin-part2/)一文中的 CDS 服务部分。

**注意**

- 在 Envoy 配置中静态定义的 cluster 不能通过 CDS API 进行修改或删除。
- Envoy 从 1.9 版本开始已不再支持 v1 API。

## 统计

CDS 的统计树以 `cluster_manager.cds.` 为根，统计如下：

| 名字                          | 类型    | 描述                                                         |
| ----------------------------- | ------- | ------------------------------------------------------------ |
| config_reload                 | Counter | 因配置不同而导致配置重新加载的总次数                         |
| update_attempt                | Counter | 尝试调用配置加载 API 的总次数                                |
| update_success                | Counter | 调用配置加载 API 成功的总次数                                |
| update_failure                | Counter | 调用配置加载 API 因网络错误的失败总数                        |
| update_rejected               | Counter | 调用配置加载 API 因 schema/验证错误的失败总次数              |
| version                       | Gauge   | 来自上次成功调用配置加载API的内容哈希                        |
| control_plane.connected_state | Gauge   | 布尔值，用来表示与管理服务器的连接状态，1表示已连接，0表示断开连接 |

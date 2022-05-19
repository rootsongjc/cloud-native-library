---
weight: 50
title: RDS（路由发现服务）
date: '2022-05-18T00:00:00+08:00'
type: book
---

路由发现服务（RDS）是 Envoy 里面的一个可选 API，用于动态获取[路由配置](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/rds.proto#envoy-api-msg-routeconfiguration)。路由配置包括 HTTP header 修改、虚拟主机以及每个虚拟主机中包含的单个路由规则配置。每个 HTTP 连接管理器都可以通过 API 独立地获取自身的路由配置。

**注意**：Envoy 从 1.9 版本开始已不再支持 v1 API。

## 统计

RDS 的统计树以 `http.<stat_prefix>.rds.<route_config_name>.*.`为根，`route_config_name`名称中的任何`:`字符在统计树中被替换为`_`。统计树包含以下统计信息：

| 名字            | 类型    | 描述                                            |
| --------------- | ------- | ----------------------------------------------- |
| config_reload   | Counter | 因配置不同而导致配置重新加载的总次数            |
| update_attempt  | Counter | 尝试调用配置加载 API 的总次数                   |
| update_success  | Counter | 调用配置加载 API 成功的总次数                   |
| update_failure  | Counter | 调用配置加载 API 因网络错误的失败总数           |
| update_rejected | Counter | 调用配置加载 API 因 schema/验证错误的失败总次数 |
| version         | Gauge   | 来自上次成功调用配置加载API的内容哈希           |

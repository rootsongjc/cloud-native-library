---
weight: 3
title: 3.3 本章小结
date: '2022-05-18T00:00:00+08:00'
type: book
---

本章中我们讨论了两种帮助我们迁移到云原生应用架构的方法：

**分解原架构**

我们使用以下方式分解单体应用：

1. 所有新功能都使用微服务形式构建。
2. 通过隔离层将微服务与单体应用集成。
3. 通过定义有界上下文来分解服务，逐步扼杀单体架构。

**使用分布式系统**

分布式系统由以下部分组成：

1. 版本化，分布式，通过配置服务器和管理总线刷新配置。
2. 动态发现远端依赖。
3. 去中心化的负载均衡策略
4. 通过熔断器和隔板阻止级联故障
5. 通过 API 网关集成到特定的客户端上

还有很多其他的模式，包括自动化测试、持续构建与发布管道等。欲了解更多信息，请阅读 Toby Clemson 的 《 Testing Strategies in a Microservice Architecture》，以及 Jez Humbl 和 David Farley（AddisonWesley）的《Continuous Delivery: Reliable Software Releases through Build, Test, and Deployment Automation》。
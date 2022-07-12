---
title: "Istio 的扩展性概述"
linktitle: "扩展性概述"
type: book
weight: 1
date: 2022-07-12T15:18:00+08:00
---

Istio 利用 WebAssembly 技术实现扩展，使用 Proxy-Wasm 沙盒 API 替换了 Istio 老版本中的 Mixer。

## WebAssembly 沙盒的目标：

- **效率**：降低扩展增加的延迟以及对 CPU 和内存的开销；
- **功能**：扩展可以执行策略，收集遥测数据，并执行有效载荷的变异；
- **隔离**：插件的编程错误或崩溃不会影响其他插件；
- **配置**：使用与其他 Istio AP I一致的 API 对插件进行配置，可以动态地配置扩展；
- **运**维：可以使用金丝雀部署，或者使用 log-only、fail-open 或 fail-close 模式部署扩展；
- **开发者**：可以用多种编程语言编写扩展；

## 架构

Istio 扩展（Proxy-Wasm 插件）由以下组成部分：

- **过滤器服务提供商接口（Filter Service Provider Interface，简称 SPI）** ：用于为过滤器构建 Proxy-Wasm 插件；
- **沙盒**：嵌入在 Envoy 中的 V8 Wasm 运行时；
- **主机 API**：用于处理请求头、尾和元数据；
- **呼出 API**：针对 gRPC 和 HTTP 请求；
- **统计和记录 API**：用于度量统计和监控；

下图展示的是 Istio 的扩展性架构。

![Istio 扩展性架构示意图](../../images/istio-extension.svg "Istio 扩展性架构示意图")
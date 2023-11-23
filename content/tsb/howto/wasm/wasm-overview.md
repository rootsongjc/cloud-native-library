---
title: WASM 扩展概述
description: 展示了什么是 WASM 扩展及其好处。
weight: 1
---

本文将描述什么是 WASM 扩展以及其好处。

## 什么是 WASM 扩展？

WASM 扩展是[WebAssembly](https://istio.io/latest/docs/concepts/wasm)的软件插件，可用于扩展 Istio 代理（Envoy）。
这些 WASM 扩展在一个沙盒环境中执行，对外部系统的访问受到限制，并且可以使用不同的编程语言及其 SDK 创建。
这个沙盒环境提供了`隔离`，以防止一个插件中的编程错误或崩溃影响其他插件，并提供了`安全性`，以防止一个插件从系统获取信息。

## WASM 扩展的好处是什么？

Envoy 可以使用`过滤器`进行扩展，有各种内置的[过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/configuration)用于不同的协议，可以配置为在网络流量的一部分执行。
通过这些过滤器（网络、HTTP）的组合，你可以增强传入请求、转换协议、收集统计信息、修改响应、执行身份验证等等。

为了拥有自定义过滤器，有几种选择：
- 使用 C++编写自己的过滤器并将其与 Envoy 打包。
  这意味着重新编译 Envoy 并维护不同版本。
- 使用依赖于 HTTP Lua 过滤器的 Lua 脚本。
  适用于简单的脚本和更复杂的部署过程。
- 使用基于 WASM 的扩展
  允许使用不同的编程语言编写复杂的脚本，并自动化部署过程。

一些 WASM 扩展的好处包括：
- 使用自定义功能扩展网关
- 应用有效载荷验证（在 Istio 过滤器上不可能，因为它们只操作元数据）
- 快速应对 CVE 或 0 天漏洞（例如 Log4Shell）
- 在 AUTHZ 和 AUTHN 上添加自定义安全验证
- 改善应用程序的安全性，而不触及其代码库

进一步阅读：
- [WASM 模块和 Envoy 的可扩展性解释](https://tetrate.io/blog/wasm-modules-and-envoy-extensibility-explained-part-1/)
- [为什么 WebAssembly 即使在浏览器之外也具有创新性](https://tetrate.io/blog/wasm-outside-the-browser/)
- [WebAssembly 对你的应用程序安全性和可扩展性能做什么](https://tetrate.io/blog/what-can-webassembly-do-for-your-application-security-and-extensibility/)
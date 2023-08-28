---
title: Overview
description: Shows what are WASM extensions and their benefits
weight: 1
---

This document will describe what's a WASM extension and its benefits.

## What's a WASM extension ?

A WASM extension is a software addon of [WebAssembly](https://istio.io/latest/docs/concepts/wasm) which can be used to extend the Istio proxy (Envoy).
These WASM extensions are executed in a sandbox environment and have limited access to the external system, and can be created using different programming languages with their SDKs.
This sandbox environment provides `isolation` to prevent that a programming error or crash in one plugin affects other plugins and `security` to avoid one plugin getting information from the system.


## What's the benefit of WASM extensions ?

Envoy can be extended using `filters`, and there are various builtin [filters](https://www.envoyproxy.io/docs/envoy/latest/configuration/configuration) for different protocols, that can be configured to be executed
as part of the networking traffic. With the combination of those filters (network, HTTP) you can augment the incoming requests, translate protocols, collect statistics,
modify the response, perform authentication, and much more.

In order to have custom filters there are several options:

- write your own filter using C++ and package it with Envoy.
  It implies recompiling Envoy and maintaining the versions.
- use Lua scripts relying on the HTTP Lua filter.
  For simple scripts and with more complex deployment process.
- use WASM based extensions
  Allows complex scripts, written in different programming languages, and it automates the deployment process.

Some benefits of WASM extensions are :
- extending gateways with custom features
- applying payload validations (not possible with Istio filters as they only operate on metadata)
- quick mitigations to CVEs or 0days ( e.g. Log4Shell )
- adding custom security validations on AUTHZ and AUTHN
- security improvements to applications without touching their code base

Further reading:
- [Wasm extensions and Envoy extensibility explained](https://tetrate.io/blog/wasm-modules-and-envoy-extensibility-explained-part-1/)
- [Why WebAssembly is innovative even outside the browser](https://tetrate.io/blog/wasm-outside-the-browser/)
- [What can WebAssembly do for your Application Security and Extensibility](https://tetrate.io/blog/what-can-webassembly-do-for-your-application-security-and-extensibility/)

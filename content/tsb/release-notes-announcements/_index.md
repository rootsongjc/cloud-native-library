---
title: "TSB 1.6 发行说明"
linktitle: "版本发行说明"
description: "Tetrate Service Bridge 1.6 发行说明。"
weight: 12
---

欢迎使用 Tetrate Service Bridge (TSB) 版本 1.6 的发行说明。此版本引入了多项新功能，可增强可用性、安全性和可见性。TSB 继续提供统一的方法来连接和保护不同环境中的服务，包括 Kubernetes 集群、虚拟机和裸机工作负载。

##  主要亮点

### 跨集群高可用性和安全性

TSB 1.6 专注于通过将远程集群更紧密地结合在一起以简化管理和可扩展性来提高可用性和安全性：

- 所有服务的跨集群高可用性：引入 `EastWestGateway` 功能，实现集群之间的自动服务故障转移，无需外部网关。最大限度地提高服务可用性、简化故障转移并增强安全性。
- 跨集群身份传播和安全域：创建跨集群的可扩展安全策略，确保本地、远程和故障转移服务的访问控制规则一致。

### 增强可见性和故障排除

- 高级可见性和跟踪工具：使应用程序开发人员能够解决跨集群的分布式应用程序中的性能问题。利用 `tctl collect` 导出运行时数据以进行离线分析，并使用 `tctl troubleshoot` 进行深入调查。

### 附加功能和灵活性

- WASM 扩展支持：使用 WebAssembly (WASM) 扩展通过自定义功能扩展代理（网关和服务代理）的功能。加速创新、降低成本并执行全球应用政策。

### 红帽 OpenShift 集成

- Red Hat OpenShift 上的可用性：TSB 1.6 可通过 Red Hat 生态系统目录在 Red Hat OpenShift 上使用。获得多集群 OpenShift 环境的可观测性、安全性和流量管理。

###  面向未来的安全

- 技术预览：Tetrate Web 应用程序防火墙 (WAF)：了解 Tetrate 即将推出的 Web 应用程序防火墙，为内部和外部的所有服务提供高级 L7 保护。

## TSB 1.6 的受益者

TSB 1.6 为组织内的各种角色带来好处：

- 平台运维者：高效管理多集群平台，提高平台用户的可用性、安全性和可见性能力，轻松驾驭异构环境。
- 服务所有者：增强跨集群的服务可用性，远程解决性能问题，并与应用程序开发人员有效协作。
- 安全团队：在零信任架构中应用精确的安全策略，确保跨集群的准确且一致的访问控制。
- 平台运维者、服务所有者和安全团队：通过 WASM 扩展使用自定义功能扩展代理功能。

## TSB 1.6 中的显着功能

### 跨集群高可用

- EastWestGateway：实现集群之间无缝、自动的服务故障转移。最大限度地提高可用性、确保透明度并增强安全性。

### 增强的故障排除功能

- 高级可见性和跟踪工具：为应用程序开发人员提供快速识别和解决性能问题的工具。

###  OpenShift 兼容性

- 经过认证的 OpenShift 兼容性：使用红帽生态系统目录在红帽 OpenShift 上自信地部署 TSB 1.6。

###  WASM 扩展

- 自定义功能：利用 WebAssembly (WASM) 扩展来增强应用程序功能并强制执行策略。

###  安全与身份

- 安全域和身份传播：部署一致的安全策略并跨集群安全地传播服务身份。

###  Istio 增强功能

- 分段和多 Istio 支持：实现隔离边界并支持集群内的多个 Istio 版本。

### Tetrate Web 应用程序防火墙 (WAF) - 技术预览

- 高级 L7 保护：深入了解即将推出的 Tetrate Web 应用程序防火墙，以实现全面的服务保护。

有关改进的完整列表，请参阅 TSB 1.6 发行说明。

##  入门

开始使用 Tetrate Service Bridge 1.6：

- 查看[初始要求](./../setup/requirements-and-download)并选择合适的平台。
- 根据你的需求选择部署选项：快速演示安装、生产就绪设置或升级现有部署。
- 请联系 Tetrate 支持寻求任何帮助。

感谢你选择 Tetrate Service Bridge！

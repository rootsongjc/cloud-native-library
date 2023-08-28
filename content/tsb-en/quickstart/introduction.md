---
title: "快速开始简介"
description: "快速开始简介。"
weight: 1
---

Welcome to the TSB Quickstart guide! This guide is designed to walk you through the process of onboarding and configuring your application on TSB. By following this quickstart, you'll learn how to deploy your application and configure TSB and its components for various basic scenarios.

In this quickstart guide, you will explore the following scenarios:

- Deploying the Istio bookinfo sample application
- Creating a tenant and connecting a cluster
- Creating a workspace
- Establishing `tctl` access to the Workspace
- Creating configuration groups
- Configuring permissions
- Setting up an Ingress Gateway
- Checking service topology and metrics
- Using TSB for traffic shifting
- Enabling security settings within TSB
- Creating an Application and configuring API with an OpenAPI spec

Before you begin with the quickstart guide, ensure that you:

- Familiarize yourself with [TSB concepts](../concepts/)
- Install the [TSB demo](../setup/self_managed/demo-installation) environment

Each example in this guide will demonstrate how to make changes using both the `tctl` command-line tool and the TSB UI.

Throughout these examples, you will be utilizing super admin privileges, granting you access to all TSB features. However, keep in mind that for production use, not everyone may be granted admin privileges. It's not recommended to provide everyone with admin access due to security considerations.

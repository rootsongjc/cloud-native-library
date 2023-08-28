---
slug: .
title: Quickstart with Workloads on-premise
---

This guide will help you to get started with `Workload Onboarding` in practice.

As part of this guide, you will:
1. Deploy [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/)
   example into your Kubernetes cluster
1. Deploy `ratings` application on a VM on-premise and onboard it into the
   service mesh
1. Verify traffic between Kubernetes Pod(s) and the VM on-premise

This guide is intended to be an easy-to-follow demonstration of the workload
onboarding capabilities.

To keep things simple, you are not required to configure the infrastructure the way
you would do it in the case of a production deployment.

Specifically:
* you are not required to set up routable DNS records
* you are not required to use a trusted CA authority (such as [Let's Encrypt])

Before proceeding, please make sure to complete the following prerequisites:
* Create a Kubernetes cluster to install TSB and example application(s) into
* Follow the instructions in [TSB demo](../../../../setup/self_managed/demo-installation)
  installation
* Follow the instructions in [Installing the Bookinfo Example](./../aws-ec2/bookinfo)
* Follow the instructions in [Enable Workload Onboarding](./../aws-ec2/enable-workload-onboarding)
* Make sure that on-premise VM and Kubernetes cluster are on the same network or
  on peered networks

[Let's Encrypt]: https://letsencrypt.org/

import DocCardList from '@theme/DocCardList';

<DocCardList />

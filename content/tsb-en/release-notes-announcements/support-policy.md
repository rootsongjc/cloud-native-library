---
title: TSB Support Policy
description: TSB support policy, release schedule, and component version matrix.
---

This document provides information about TSB's release cadence, support periods for different versions, and the component version matrix.

## TSB Releases Explained

TSB follows a semantic versioning model based on [semver.org](https://semver.org). Here's what each version number represents:

- `MAJOR`: Incremented for incompatible API changes.
- `MINOR`: Incremented for new features.
- `PATCH`: Incremented for bug and security fixes.

### TSB Release Cadence and Support

- TSB releases `PATCH` updates (1.x.y) regularly and at least quarterly.
- Each new `MINOR` release falls under the Long Term Support (LTS) policy.
- Tetrate provides support for LTS versions from General Availability (GA) up to End of General Support (EoGS), typically set 12 months after GA.
- Bug and security fixes are provided through `PATCH` releases during the support window.
- New features are not backported to LTS versions.

### TSB Release Candidate Versions

Release candidate versions offer early access to new features for testing but are not recommended for production use.

{{<callout warning "Release Candidates">}}
Release candidates may contain known or unknown bugs and are not meant for production usage.
{{</callout>}}

## Supported Versions

Tetrate provides support and patches according to the following schedule:

| TSB Version | General Availability | End of General Support | Kubernetes Versions | OpenShift Versions |
| ----------- | -------------------: | ---------------------: | ------------------- | ------------------ |
| TSB v1.6.x  |      1 January, 2023 |      31 December, 2023 | 1.22 - 1.26 [1]     | 4.7 - 4.12 [1]     |
| TSB v1.5.x  |        15 July, 2022 |          15 July, 2023 | 1.19 - 1.24         | 4.6 - 4.11         |
| TSB v1.4.x  |     1 November, 2021 |       31 October, 2022 | 1.18 - 1.21 [2]     | 4.6 - 4.8          |
| TSB v1.3.x  |         1 June, 2021 |           31 May, 2022 | 1.18 - 1.20         | 4.6 - 4.8          |
| TSB v1.2.x  |          1 May, 2021 |         30 April, 2022 | 1.18 - 1.20 [3]     | 4.6 - 4.8          |
| TSB v1.1.x  |        1 April, 2021 |         31 March, 2022 |                     |                    |
| TSB v1.0.x  |        1 March, 2021 |      28 February, 2022 |                     |                    |

### Notes

- [1] Kubernetes 1.25, 1.26, and OpenShift 4.12 require TSB 1.6.1 or later.
- [2] Kubernetes 1.21 and TSB 1.4.x - supported with caveats, please refer to Tetrate support.
- [3] Kubernetes 1.19 and 1.20 and TSB 1.2.x - supported with caveats, please refer to Tetrate support.

## TSB Component Version Matrix

Tetrate Service Bridge includes the following open source components:

| TSB   | Istio  | Envoy   | SkyWalking          | Zipkin | OpenTelemetry Collector |
| ----- | ------ | ------- | ------------------- | ------ | ----------------------- |
| 1.6.3 | 1.15.7 | 1.23.11 | 9.4.0-20230726-0846 |        | 0.81.0                  |
| 1.6.2 | 1.15.7 | 1.23.7  | 9.4.0-20230407-0339 |        | 0.77.0                  |
| 1.6.1 | 1.15.7 | 1.23.7  | 9.4.0-20230331-1055 | 2.24.0 | 0.70.0                  |
| 1.6.0 | 1.15.2 | 1.23.2  | 9.4.0-20221215-0956 | 2.24.0 | 0.62.1                  |

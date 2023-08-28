---
title: Onboarding on-premise workloads
description: How to onboard on-premise workloads
---

This document describes the steps to onboard on-premise workloads to TSB using
the Workload Onboarding feature.

Before you proceed, make sure that you have completed the steps described in
[Setting Up Workload Onboarding document](./setup).

## Context

Every workload that gets onboarded into the mesh by the Workload Onboarding
must have a verifiable identity.

VMs in the cloud have a verifiable identity out-of-the-box. Such identity is
provided by the respective cloud platform.

On-premise environments, however, are a black box. Whether or not your
on-premise workloads have a verifiable identity depends solely on your own
technology stack.

Therefore, to be able to onboard on-premise workloads, you need to ensure
they have a verifiable identity in the form of a
[JWT Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

## Overview

The setup for Workload Onboarding of on-premise workloads consists of the
following extra steps:

1. Configure trusted JWT Issuers
1. Allow on-premise workloads to join WorkloadGroup
1. Configure Workload Onboarding Agent to use your custom Credential Plugin
1. Onboard on-premise workload

## Configure trusted JWT Issuers

To configure a list of JWT Issuers that are trusted to assert identity of the
on-premise workloads, edit TSB
[`ControlPlane`](../../../refs/install/controlplane/v1alpha1/spec) CR or Helm values as follows:

```yaml
spec:
  ...
  meshExpansion:
    onboarding:
      ...
      # extra configuration specific to on-premise workloads
      workloads:
        authentication:
          jwt:
            issuers:
            - issuer: <jwt-issuer-id>                        # (1) REQUIRED
              shortName: <short-name>                        # (2) REQUIRED
              jwksUri: <jwks-uri>                            # (3) OPTIONAL
              jwks: |
                # {
                #   "keys": [
                #     ...
                #   ]
                # }
                <inlined-jwks-document>                      # (4) OPTIONAL
              tokenFields:
                attributes:
                  jsonPath: <jwt-attributes-field-jsonpath>  # (5) OPTIONAL
```

where

1. You must specify a JWT `Issuer ID` to trust to, e.g. `https://mycompany.corp`
1. You must specify a short name to associate with that Issuer, e.g. `my-corp`
1. You can specify a URI to fetch JWKS document with signing keys from, e.g.
   `https://mycompany.corp/jwks.json`
1. You can specify a JWKS document with signing keys in place
1. You can specify which field inside of the JWT token holds a map of attributes
   associated with the workload, e.g. `.custom_attrubutes`

## Allow on-premise workloads to join WorkloadGroup

To allow on-premise workloads to join certain WorkloadGroups, create an
[OnboardingPolicy](../../../refs/onboarding/config/authorization/v1alpha1/policy)
with the following configuration:

```yaml
apiVersion: authorization.onboarding.tetrate.io/v1alpha1
kind: OnboardingPolicy
metadata:
  name: <name>
  namespace: <namespace>
spec:
  allow:
  - workloads:
    - jwt:
        issuer: <jwt-issuer-id>                          # (1) REQUIRED
        subjects:
        - <subject>                                      # (2) OPTIONAL
        attributes:
        - name: <attribute-name>                         # (3) OPTIONAL
          values:
          - <attribute-value>
    onboardTo:
    - workloadGroupSelector: {} # any WorkloadGroup from that namespace
```

where

1. You must specify a JWT `Issuer ID` this rule applies to, e.g.
   `https://mycompany.corp`
1. You can specify an explicit list of JWT subjects this rule applies to, e.g.
   `us-east-datacenter1-vm007`
1. You can specify what workload attributes a JWT must have for this rule to apply,
   e.g. `region=us-east`

## Configure Workload Onboarding Agent to use your custom Credential Plugin

To be able to onboard on-premise workloads, you need to use a Credential Plugin
that generates a [JWT Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
credential for a given workload.

First, install your custom Credential Plugin on that VM, e.g. at
`/usr/local/bin/onboarding-agent-<your-plugin-name>-plugin`.

Then, [configure Workload Onboarding Agent](../../../refs/onboarding/config/agent/v1alpha1/agent_configuration)
to use that plugin.
For that, edit `/etc/onboarding-agent/onboarding.config.yaml` as follows:

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  custom:
    credential:
    - plugin:
        name: <your-plugin-name>                                         # (1) REQUIRED
        path: /usr/local/bin/onboarding-agent-<your-plugin-name>-plugin  # (2) OPTIONAL
        args:
        - <your-plugin-arg>                                              # (3) OPTIONAL
        env:
        - name: <YOUR_PLUGIN_CONFIG>                                     # (4) OPTIONAL
          value: "<your-plugin-config-value>"
```

where

1. You must specify a name of your Credential Plugin, e.g. `my-jwt-credential`
1. You can specify a path to the plugin binary, e.g. `/usr/local/bin/onboarding-agent-my-jwt-credential-plugin`
1. You can specify additional command-line arguments that Workload Onboarding Agent
   must pass when executing your plugin binary, e.g. `--my-arg=my-value`
1. You can specify additional environment variables that Workload Onboarding Agent
   must set when executing your plugin binary, e.g. `MY_CONFIG="some value"`

## Onboard on-premise workload

To onboard an on-premise workload, [follow the same steps](./onboarding)
as in the case of a VM in the cloud.

---
title: TSB Operator
description: Introduction to the concepts of the TSB Operator.
---

This section will introduce you to the concepts of the TSB Operator. You'll
learn how the TSB Operator manages the lifecycle of TSB including install,
upgrade and runtime behaviours of TSBs various planes.


:::note Kubernetes knowledge 
If you're not familiar with Kubernetes namespaces, operators, manifests, and
custom resources we advise you to read up on these concepts. It will make it
much easier to understand our TSB Operator and maintain a TSB service mesh.

Please consult the Kubernetes documentation for more information on the
[Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
:::

The TSB Operator controls the install, upgrade, and runtime behaviors of TSB
management, control, and data plane components. To ensure compatibility and make
the upgrade experience smooth, the Kubernetes-based manifests of the TSB
components are compiled into the TSB Operator. Therefore, the versions of the
management, control, and data plane components are pinned to the version of the
TSB operator deployment that governs them. With the help of the user-created
custom resources (CR), the operator can configure and instantiate the
components. 

To manage the TSB lifecycle, the TSB Operator works closely with the `tctl` CLI
tool. With `tctl` you can create the bootstrap TSB Operator manifests that
allows you to install and configure the TSB Operator in the management, control,
and data planes. 

Each plane needs a copy of the TSB Operator, and when installed, will be
configured to watch for the appropriate CRs for that specific plane. TSB
Operator actions are determined by a combination of:
- the bundled TSB component manifests inside the TSB Operator, 
- the contents of the CRs found in the watched namespaces by the TSB Operator, 
- the existence of TSB components running under the control of the TSB Operator.
  

TSB lifecycle management with TSB Operators typically takes the form of
reconciliation between the existing state and the desired state. 

Here are the key points concerning TSB Operator lifecycle actions:

- CRs being **available** tells the TSB Operator that it needs to have all
  components for its pinned TSB version deployed using the configuration details
  found in the CRs.
- CRs being **unavailable** tells the TSB Operator that it needs to verify that
  there are no TSB components running. TSB will remove any components deployed
  under the control of the TSB Operator.
- Updating a TSB Operator bootstrap manifest with a newer version of the
  Operator listed inside it, will force a TSB upgrade if CRs are already
  available.
- Updating CRs will reconfigure an existing TSB installation to use the new
  configuration details.
- TSB components running different versions than those listed in the embedded
  manifests of the Operator are automatically removed in favor of the listed
  versions.
- Any TSB components deemed missing (e.g. if they're accidentally removed by a
  user) are recreated according to the TSB Operator's pinned version, and CR
  configuration.




import DocCardList from '@theme/DocCardList';

<DocCardList />

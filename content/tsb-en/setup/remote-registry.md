---
title: Repository secrets
description: Configuring TSB to pull container images from the remote private repository
---

Starting with version 1.5, TSB provides an automated way to obtain images from a remote private Docker container repository by defining `imagePullSecrets` in [ManagementPlane](../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec) and [ControlPlane](../refs/install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-controlplanespec) CRs.
If `imagePullSecrets` is defined, the required ServiceAccounts will be patched with the credentials from the secret, allowing for secure access to the containers that are stored in the remote private repository. The following steps outline the configuration process:

## Synchronizing images

TSB images are located in Tetrate's repository and only available for copying to your repository (no direct download to any environment is allowed). The first step is to transfer the images to your repository. To synchronize the images, you need to use `tctl install image-sync` per the [documentation](../setup/requirements-and-download#sync-tetrate-service-bridge-images) (a license key provided by Tetrate is required).

## Obtain JSON key for the private repository

The secret that is specified as `imagePullSecrets` will store credentials that allow kubernetes to pull the required containers from the private repository. The way to obtain the credentials depends on the repository. Please refer to the following links to get some guidance on major cloud providers - [AWS](https://medium.com/clarusway/how-to-use-images-from-a-private-container-registry-for-kubernetes-aws-ecr-hosted-private-13a759e2c4ea), [GCP](https://blog.container-solutions.com/using-google-container-registry-with-kubernetes) and [Azure](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes).

## Create secrets in every namespace used by TSB

As stated in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/secret/#details), secrets can only be accessed by pods within the same namespace they are created in. Therefore, a separate secret must be created for each namespace used by TSB. Note that the available namespaces may vary depending on the Kubernetes platform.

Currently, the following namespaces require a separate secret:

- For the TSB Management Plane cluster `tsb` and `cert-manager` (if using the internal TSB packaged cert-manager) 
- For the TSB Control Plane cluster `istio-system`, `istio-gateway`, `cert-manager` (if using the internal TSB packaged cert-manager)  and `kube-system` (if using Istio CNI)

:::note Additional namespaces
The list provided above is not exhaustive. Additional namespaces may be used for TSB components on different platforms and therefore will require a separate secret to be created. To check if there are any pods experiencing issues obtaining the container image, use the command `kubectl get pods -A | grep ImagePullBackOff`.
:::

## Application namespaces

To make sure that istio enabled application, can download images. The repository credentials secret is required to be present in every application namespace with istio-sidecar enabled pods and ingress gateways.

## Install TSB 

To install TSB, use your preferred method, but ensure that the ManagementPlane and ControlPlane CRs have `imagePullSecrets` configured as follows:

```yaml
  spec:
    ...
    imagePullSecrets:
    - name: <secret name created in previous step>
    ...
```

## Patch operator ServiceAccounts

Images of TSB Operators require credentials before the operators are able to propagate the `imagePullSecrets` to the rest of components.

The steps are the following:
- Patch the ServiceAccounts for TSB operator in `istio-system` and `istio-gateway` namespaces:

    ```bash
    kubectl patch serviceaccount tsb-operator-control-plane -p '{"imagePullSecrets": [{"name": "<secret name created per steps above>"}]}' -n istio-system
    kubectl patch serviceaccount tsb-operator-data-plane -p '{"imagePullSecrets": [{"name": "<secret name created per steps above>"}]}' -n istio-gateway
    ```

- Restart the operators in these namespaces:

    ```bash
    kubectl delete pod -n istio-system -l=name=tsb-operator 
    kubectl delete pod -n istio-gateway -l=name=tsb-operator
    kubectl delete pod -n istio-gateway -l=name=istio-operator
    ```

:::note Helm chart installation
Steps to create secrets and define the `imagePullSecrets` can be automated using [Helm installation](./helm)
:::
:::note Sequence of steps
It's very important that the Kubernetes secret for the private repository is created before installing TSB. Following this proper sequence will allow for efficient deployment and will minimize any downtime.
:::

---
title: Migration from tctl to Helm
weight: 14
---

This document will cover how to migrate a live installation of TSB using tctl and migrate to helm. The document assumes that [Helm is already installed](https://helm.sh/docs/intro/install/ ) in the system.

Before you get started, make sure you:<br />
✓ Familiarize yourself with [TSB concepts](../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../quickstart).<br />

## Preparation of the helm charts

Before hand you must be familiar with Helm. Follow the [prerequisites](helm/helm) in our guide with installing TSB with Helm.  


## Migrate Management Plane

Migrating the current installation requires only labeling and annotating the resources of the plane installation. All other components will be upgraded and managed by the tsb-operator.
Here is list of commands to annotate every resource that will be managed by Helm.

````
kubectl -n tsb label deployment tsb-operator-management-plane "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate deployment tsb-operator-management-plane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb annotate service tsb-operator-management-plane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb annotate sa tsb-operator-management-plane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret elastic-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret elastic-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret es-certs "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret es-certs "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret ldap-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret ldap-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret postgres-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret postgres-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label secret admin-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate secret admin-credentials "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl annotate clusterrole tsb-operator-management-plane-tsb "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl annotate clusterrolebinding tsb-operator-management-plane-tsb "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

kubectl -n tsb label managementplane managementplane "app.kubernetes.io/managed-by=Helm"
kubectl -n tsb annotate managementplane managementplane "meta.helm.sh/release-name=mp" "meta.helm.sh/release-namespace=tsb"

````

:::note Attention
release-name and release-namespace should match the release name and namespace used in the helm install command.
:::

After all the resources are labeled correctly then proceed with the installation of the release:

````
###Example
helm upgrade mp tetrate-tsb-helm/managementplane --install --namespace tsb -f upgrade-mpt1/helm/values-mp.yaml --set image.registry=${HUB} --set image.tag=${TSB_VERSION} --set spec.hub=${HUB} 

###Output:
Release "mp" does not exist. Installing it now.


NAME: mp
LAST DEPLOYED: Thu May 25 11:03:18 2023
NAMESPACE: tsb
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the TSB Management plane 1.5.11.
Chart: managementplane
Version: 1.5.11

Your Management Plane is ready to be used.
Next step might be to onboard the cluster from the control plane.
You could choose between:
 - install `controlplane` chart
 - manually following # TODO url to docs.

# Discover the TSB entrypoint

Check the IP for the envoy loadbalancer service.

This is one example. Consider a time for the service to be ready:
kubectl get svc -n "tsb" envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Configure the TCTL admin profile, using the IP in the previous step.

# Setup the TSB address as follows. If specific settings are needed to trust the certificate configured in TSB,
# refer to the `tctl config clusters set --help` command to see all the available options.
tctl config clusters set helm --bridge-address <IP>:8443

tctl config users set helm --username admin --password "NotAPassword" --org "tetrate"
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm 
````

## Migrate Control Plane

The procedure is the same, only a few resources and secrets are changed

````
kubectl -n istio-system label deployment tsb-operator-control-plane "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate deployment tsb-operator-control-plane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system annotate service tsb-operator-control-plane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system annotate sa tsb-operator-control-plane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label secret elastic-credentials "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret elastic-credentials "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label secret cluster-service-account "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret cluster-service-account "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label secret mp-certs "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret mp-certs "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label secret xcp-central-ca-bundle "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate secret xcp-central-ca-bundle "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl annotate clusterrole tsb-operator-control-plane-istio-system "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl annotate clusterrolebinding tsb-operator-control-plane-istio-system "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

kubectl -n istio-system label controlplane  controlplane "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-system annotate controlplane controlplane "meta.helm.sh/release-name=cp" "meta.helm.sh/release-namespace=istio-system"

````

Verify and check that release-name and release-namespace points to the one in the release installation:

````
###Example
helm upgrade cp tetrate-tsb-helm/controlplane --install --namespace istio-system -f upgrade-mpt1/helm/values-cp.yaml  --set image.registry=${HUB} --set image.tag=${TSB_VERSION} --set spec.hub=${HUB} --set spec.managementPlane.host=${TSB_HOST} --set-file secrets.clusterServiceAccount.JWK=/tmp/upgrade-mpt1.jwk

###Output
Release "cp" does not exist. Installing it now.
NAME: cp
LAST DEPLOYED: Thu May 25 11:21:18 2023
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the TSB Control Plane 1.5.11.
Chart: controlplane
Version: 1.5.11

````

## Migrate Data Plane

This is the last plane, and have fewer resources to annotate:

````
kubectl -n istio-gateway label deployment tsb-operator-data-plane "app.kubernetes.io/managed-by=Helm"
kubectl -n istio-gateway annotate deployment tsb-operator-data-plane "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl -n istio-gateway annotate service tsb-operator-data-plane "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl -n istio-gateway annotate sa tsb-operator-data-plane "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl annotate clusterrole tsb-operator-data-plane-istio-gateway "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

kubectl annotate clusterrolebinding tsb-operator-data-plane-istio-gateway "meta.helm.sh/release-name=dp" "meta.helm.sh/release-namespace=istio-gateway"

````

Proceed to install the release:

````
###Example
helm upgrade dp tetrate-tsb-helm/dataplane --install --namespace istio-gateway --create-namespace --set image.registry=${HUB} --set image.tag=${TSB_VERSION}

###Output
Release "dp" does not exist. Installing it now.

NAME: dp
LAST DEPLOYED: Thu May 25 11:29:11 2023
NAMESPACE: istio-gateway
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the TSB Data Plane 1.5.11.
Chart: dataplane
Version: 1.5.11

````

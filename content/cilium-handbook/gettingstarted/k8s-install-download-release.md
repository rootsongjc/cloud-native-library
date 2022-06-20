::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <https://docs.cilium.io>
:::

::: {.note}
::: {.title}
Note
:::

Make sure you have Helm 3
[installed](https://helm.sh/docs/intro/install/). Helm 2 is [no longer
supported](https://helm.sh/blog/helm-v2-deprecation-timeline/).
:::

::: {.only}
stable

Setup Helm repository:

``` {.shell-session}
helm repo add cilium https://helm.cilium.io/
```
:::

::: {.only}
not stable

Download the Cilium release tarball and change to the kubernetes install
directory:

::: {.parsed-literal}
curl -LO tar xzf cd /install/kubernetes
:::
:::

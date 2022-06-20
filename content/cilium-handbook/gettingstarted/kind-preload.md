Preload the `cilium` image into each worker node in the kind cluster:

::: {.parsed-literal}
docker pull quay.io/cilium/cilium: kind load docker-image
quay.io/cilium/cilium:
:::

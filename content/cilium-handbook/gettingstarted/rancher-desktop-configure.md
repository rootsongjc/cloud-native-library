Configuring Rancher Desktop is done using a YAML configuration file.
This step is necessary in order to disable the default CNI and replace
it with Cilium.

Next you need to start Rancher Desktop with `containerd` and create a
`override.yaml <rancher-desktop-override.yaml>`{.interpreted-text
role="download"}:

::: {.literalinclude language="yaml"}
rancher-desktop-override.yaml
:::

After the file is created move it into your Rancher Desktop\'s
`lima/_config` directory:

::: {.tabs}
.. group-tab:: Linux

``` {.shell-session}
cp override.yaml ~/.local/share/rancher-desktop/lima/_config/override.yaml
```

::: {.group-tab}
macOS
:::

``` {.shell-session}
cp override.yaml ~/Library/Application\ Support/rancher-desktop/lima/_config/override.yaml
```
:::

Finally, open the Rancher Desktop UI and go to Kubernetes Settings panel
and click \"Reset Kubernetes\".

After a few minutes Rancher Desktop will start back up prepared for
installing Cilium.

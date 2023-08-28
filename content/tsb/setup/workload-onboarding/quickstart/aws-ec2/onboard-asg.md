---
title: Onboard Workload(s) from AWS Auto Scaling Group
---

To onboard a workload deployed on `AWS Auto Scaling Group` (`ASG`), you will need to
perform all setup actions as part of the [instance launch script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
instead of executing commands on the EC2 instance.

In a nutshell, you will need to move setup commands from previous steps into the
[cloud-init](https://cloudinit.readthedocs.io/en/latest/) configuration associated
with instances in the Auto Scaling Group.

Specifically,

1. Move setup commands from the [Install Bookinfo Ratings application](./configure-vm#install-bookinfo-ratings-application) step
1. Move setup commands from the [Install Istio sidecar](./configure-vm#install-istio-sidecar) step
1. Move setup commands from the [Install Workload Onboarding Agent on AWS EC2 instance](./configure-vm#install-workload-onboarding-agent) step
1. Move setup commands from the [Onboard workload from AWS EC2 instance](./onboard-vm) step

The following configuration is a sample that has all of the steps joined together.
Replace `example-ca-certificate` with the with [the value of example-ca.crt.pem](./enable-workload-onboarding#prepare-the-certificates), and `ONBOARDING_ENDPOINT_ADDRESS` with [the value that you have obtained earlier](./enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```yaml
#cloud-config

write_files:
# Certificate of the custom CA
- content: |
    <example-ca-certificate>
  path: /usr/local/share/ca-certificates/example-ca.crt
  owner: root:root
  permissions: '0644'
# Onboarding Configuration
- content: |
    apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
    kind: OnboardingConfiguration
    onboardingEndpoint:
      host: <ONBOARDING_ENDPOINT_ADDRESS>
      transportSecurity:
        tls:
          sni: onboarding-endpoint.example
    workloadGroup:
      namespace: bookinfo
      name: ratings
    workload:
      labels:
        version: v5
    settings:
      connectedOver: INTERNET
  path: /etc/onboarding-agent/onboarding.config.yaml
  owner: root:root
  permissions: '0644'

runcmd:
- |
  #!/usr/bin/env bash

  set -ex

  # Install the latest version of trusted CA certificates
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates
  # Trust certificate of the custom CA
  sudo update-ca-certificates

  # Install Bookinfo ratings app
  curl --fail --silent --location https://deb.nodesource.com/setup_14.x | sudo bash -
  sudo apt-get install -y nodejs
  curl -fLO https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/bookinfo-ratings.deb
  sudo apt-get install -y ./bookinfo-ratings.deb
  rm bookinfo-ratings.deb
  sudo systemctl enable bookinfo-ratings
  sudo systemctl start bookinfo-ratings

  ONBOARDING_ENDPOINT_ADDRESS=<ONBOARDING_ENDPOINT_ADDRESS>

  # Install Istio Sidecar
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
    "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb"
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
    "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb.sha256"
  sha256sum --check istio-sidecar.deb.sha256
  sudo apt-get install -y ./istio-sidecar.deb
  rm istio-sidecar.deb istio-sidecar.deb.sha256

  # Install Workload Onboarding Agent
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
   "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb"
  curl -fLO \
    --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
    "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb.sha256"
  sha256sum --check onboarding-agent.deb.sha256
  sudo apt-get install -y ./onboarding-agent.deb
  rm onboarding-agent.deb onboarding-agent.deb.sha256
  sudo systemctl enable onboarding-agent
  sudo systemctl start onboarding-agent
```

Once the data is associated with the user data of your Auto Scaling Group,
try scaling up and down the Auto Scaling Group, and verify that 
[the Workload is onboarded properly](./onboard-vm#verify-the-workload)

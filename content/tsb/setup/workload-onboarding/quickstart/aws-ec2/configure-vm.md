---
title: Configure the VM
---

## Launch an AWS EC2 Instance

Launch an AWS EC2 instance with the following configuration:

1. Choose `64-bit (x86)` AMI image with `Ubuntu Server` (DEB)
1. Choose a minimal `Instance Type`, e.g. `t2.micro` (1x vCPU, 1 GiB RAM)
   or `t2.nano` (1x vCPU, 0.5 GiB RAM)
1. Choose the default VPC (for your instance to have public IP)
1. Set `Auto-assign Public IP` to `Enable`
1. Configure `SecurityGroup` to allow `incoming` traffic to port `9080` from `0.0.0.0/0`

For the purposes of this guide, you will be creating an EC2 instance with a public IP
for ease of configuration.

:::warning
This is *NOT* recommended for production scenarios. For production scenarios, you should
do the opposite and place the Kubernetes cluster and the EC2 instances on the same network,
or peered networks, and not give your VMs public IPs.
:::

## Install Bookinfo Ratings Application

SSH into the AWS EC2 instance you have created, and install the
`ratings` application. Execute the following commands:

```bash{promptUser: "alice"}
# Install the latest version of trusted CA certificates
sudo apt-get update -y
sudo apt-get install -y ca-certificates

# Add DEB repository with Node.js
curl --fail --silent --location https://deb.nodesource.com/setup_14.x | sudo bash -

# Install Node.js
sudo apt-get install -y nodejs

# Download DEB package of the Bookinfo Ratings app
curl -fLO https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/bookinfo-ratings.deb

# Install DEB package
sudo apt-get install -y ./bookinfo-ratings.deb

# Remove downloaded file
rm bookinfo-ratings.deb

# Enable SystemD Unit
sudo systemctl enable bookinfo-ratings

# Start Bookinfo Ratings app
sudo systemctl start bookinfo-ratings
```

## Verify the `ratings` Application

Execute the following command to verify that the `ratings` application
can now serve local requests:

```bash{promptUser: "alice"}
curl -fsS http://localhost:9080/ratings/1
```

You should get output similar to:

```json
{"id":1,"ratings":{"Reviewer1":5,"Reviewer2":4}}
```

## Configure to Trust the Example CA

Remember that you have previously configured the Workload Onboarding Endpoint using a TLS certificate signed by a custom CA. As a result, any software that runs on the AWS EC2 instance and attempts to connect to the Workload Onboarding Endpoint will not trust its certificate by default.

Before proceeding further, you must configure the EC2 instance to trust your custom CA.

First, update the `apt` package list:

```bash{promptUser: "alice"}
sudo apt-get update -y
```

Then install the `ca-certificates` package:

```bash{promptUser: "alice"}
sudo apt-get install -y ca-certificates
```

Copy the contents of the file `example-ca.crt.pem` that you have 
[created when you setup the certificates](./enable-workload-onboarding#prepare-the-certificates),
and place it under the location
`/usr/local/share/ca-certificates/example-ca.crt` on the EC2 instance.

Use your favorite tool to do this. If you have not installed any
editors or tools, you could use the combination of `cat` and `dd` as follows:

1. Execute `cat <<EOF | sudo dd of=/usr/local/share/ca-certificates/example-ca.crt`
1. Copy the contents of `example-ca.crt.pem` and paste it in the terminal that you executed the previous step
1. Type `EOF` and press `Enter` to finish the first command

After you have placed the custom CA in the correct location, execute the following
command:

```bash{promptUser: "alice"}
sudo update-ca-certificates
```

This will reload the list of trusted CAs, and it will include your custom CA.

## Install Istio Sidecar

Install the Istio sidecar by executing the following commands. Replace `ONBOARDING_ENDPOINT_ADDRESS` with [the value that you have obtained earlier](./enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```bash{promptUser: "alice"}
# Download DEB package
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb"

# Download checksum
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/istio-sidecar.deb.sha256"

# Verify the checksum
sha256sum --check istio-sidecar.deb.sha256

# Install DEB package
sudo apt-get install -y ./istio-sidecar.deb

# Remove downloaded files
rm istio-sidecar.deb istio-sidecar.deb.sha256
```

## Install Workload Onboarding Agent

Install the Workload Onboarding Agent by executing the following commands. Replace `ONBOARDING_ENDPOINT_ADDRESS` with [the value that you have obtained earlier](./enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```bash{promptUser: "alice"}
# Download DEB package
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb"

# Download checksum
curl -fLO \
  --connect-to "onboarding-endpoint.example:443:${ONBOARDING_ENDPOINT_ADDRESS}:443" \
  "https://onboarding-endpoint.example/install/deb/amd64/onboarding-agent.deb.sha256"

# Verify the checksum
sha256sum --check onboarding-agent.deb.sha256

# Install DEB package
sudo apt-get install -y ./onboarding-agent.deb

# Remove downloaded files
rm onboarding-agent.deb onboarding-agent.deb.sha256
```

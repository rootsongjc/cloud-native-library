---
title: Configure the VM on-premise
---

## Install Bookinfo Ratings Application

SSH into the VM on-premise and install the
`ratings` application. Execute the following commands:

```bash
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

```bash
curl -fsS http://localhost:9080/ratings/1
```

You should get output similar to:

```json
{"id":1,"ratings":{"Reviewer1":5,"Reviewer2":4}}
```

## Configure to Trust the Example CA

Remember that you have previously configured the Workload Onboarding Endpoint
using a TLS certificate signed by a custom CA. As a result, any software that
runs on the VM on-premise and attempts to connect to the
Workload Onboarding Endpoint will not trust its certificate by default.

Before proceeding further, you must configure the VM on-premise to trust your custom CA.

First, update the `apt` package list:

```bash
sudo apt-get update -y
```

Then install the `ca-certificates` package:

```bash
sudo apt-get install -y ca-certificates
```

Copy the contents of the file `example-ca.crt.pem` that you have 
[created when you setup the certificates](../aws-ec2/enable-workload-onboarding#prepare-the-certificates),
and place it under the location
`/usr/local/share/ca-certificates/example-ca.crt` on the VM on-premise.

Use your favorite tool to do this. If you have not installed any
editors or tools, you could use the combination of `cat` and `dd` as follows:

1. Execute `cat <<EOF | sudo dd of=/usr/local/share/ca-certificates/example-ca.crt`
1. Copy the contents of `example-ca.crt.pem` and paste it in the terminal that you executed the previous step
1. Type `EOF` and press `Enter` to finish the first command

After you have placed the custom CA in the correct location, execute the following
command:

```bash
sudo update-ca-certificates
```

This will reload the list of trusted CAs, and it will include your custom CA.

## Install Istio Sidecar

Install the Istio sidecar by executing the following commands.
Replace `ONBOARDING_ENDPOINT_ADDRESS` with
[the value that you have obtained earlier](../aws-ec2/enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```bash
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

Install the Workload Onboarding Agent by executing the following commands.
Replace `ONBOARDING_ENDPOINT_ADDRESS` with
[the value that you have obtained earlier](../aws-ec2/enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```bash
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

## Install Sample JWT Credential Plugin

For the purposes of this guide, you will be using `Sample JWT Credential Plugin`
to provide your on-premise workload with a [JWT Token] credential.

Execute the following commands to install `Sample JWT Credential Plugin`:

```bash
curl -fL "https://dl.cloudsmith.io/public/tetrate/onboarding-examples/raw/files/onboarding-agent-sample-jwt-credential-plugin_0.0.1_$(uname -s)_$(uname -m).tar.gz" \
 | tar -xz onboarding-agent-sample-jwt-credential-plugin
sudo mv onboarding-agent-sample-jwt-credential-plugin /usr/local/bin/
```

Copy the contents of the file `sample-jwt-issuer.jwk` that you have 
[created earlier](./configure-workload-onboarding#allow-workloads-to-authenticate-themselves-by-means-of-a-jwt-token),
and place it under the location
`/var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk` on the VM on-premise.

Use your favorite tool to do this. If you have not installed any
editors or tools, you could use the combination of `cat` and `dd` as follows:

1. Execute
```bash
   sudo mkdir -p /var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/
   cat <<EOF | sudo dd of=/var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk
   ```
1. Copy the contents of `sample-jwt-issuer.jwk` and paste it in the terminal that you executed the previous step
1. Type `EOF` and press `Enter` to finish the first command
1. Execute
```bash
   sudo chmod 400 /var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk
   sudo chown onboarding-agent: -R /var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/
   ```

## Configure Workload Onboarding Agent

Execute the following command to save [Agent Configuration](../../../../refs/onboarding/config/agent/v1alpha1/agent_configuration)
into the file `/etc/onboarding-agent/agent.config.yaml`:

```bash
cat << EOF | sudo tee /etc/onboarding-agent/agent.config.yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: AgentConfiguration
host:
  custom:
    credential:
    - plugin:
        name: sample-jwt-credential
        path: /usr/local/bin/onboarding-agent-sample-jwt-credential-plugin
        env:
        - name: SAMPLE_JWT_ISSUER
          value: "https://sample-jwt-issuer.example"
        - name: SAMPLE_JWT_ISSUER_KEY
          value: "/var/run/secrets/onboarding-agent-sample-jwt-credential-plugin/jwt-issuer.jwk"
        - name: SAMPLE_JWT_SUBJECT
          value: "vm007-datacenter1-us-east.internal.corp"
        - name: SAMPLE_JWT_ATTRIBUTES_FIELD
          value: "custom_attributes"
        - name: SAMPLE_JWT_ATTRIBUTES
          value: "instance_name=vm007-datacenter1-us-east,instance_role=app-ratings,region=us-east"
EOF
```

Through various environment variables, supported by the `Sample JWT Credential Plugin`,
you have configured the desired contents of the [JWT Token].


[JWT Token]: https://openid.net/specs/openid-connect-core-1_0.html#IDToken

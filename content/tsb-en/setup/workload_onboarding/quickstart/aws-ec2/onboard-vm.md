---
title: Onboard Workload from VM
---

## Start Workload Onboarding Agent

Create the file `/etc/onboarding-agent/onboarding.config.yaml` with the following contents.
Replace `ONBOARDING_ENDPOINT_ADDRESS` with [the value that you have obtained earlier](./enable-workload-onboarding#verify-the-workload-onboarding-endpoint).

```yaml
apiVersion: config.agent.onboarding.tetrate.io/v1alpha1
kind: OnboardingConfiguration
onboardingEndpoint:
  host: "<ONBOARDING_ENDPOINT_ADDRESS>"
  transportSecurity:
    tls:
      sni: onboarding-endpoint.example    # (1)
workloadGroup:                            # (2)
  namespace: bookinfo
  name: ratings
workload:
  labels:
    version: v5                           # (3)
settings:
  connectedOver: INTERNET                 # (4)
```

This configuration instructs the Workload Onboarding Agent to connect
to the Workload Onboarding Endpoint using one address, but validate
the TLS certificate against the DNS name `onboarding-endpoint.example` (1).

The agent will attempt to join the `WorkloadGroup` you created earlier (2).

The extra label specified in (3) will be associated with the workload.
It does not play a part in matching the workload with a `WorkloadGroup`.

This configuration also instructs the Workload Onboarding Agent to
notify that this workload is connected to the rest of the mesh over
the `INTERNET` (rather than `VPC`). Other nodes in the mesh will
attempt to connect to this workload using the workload's public IP.
Since you have launched the Kubernetes cluster and the EC2 instance
in separate networks, this is necessary.

Once you have placed the above configuration file in the correct
location, execute the following commands to start the Workload Onboarding Agent:

```bash{promptUser: "alice"}
# Enable
sudo systemctl enable onboarding-agent

# Start
sudo systemctl start onboarding-agent
```

Verify that `Istio Sidecar` is up by executing the following command:

```bash{promptUser: "alice"}
curl -f -i http://localhost:15000/ready
```

You should get output similar to the following:

```bash{promptUser: "alice"}
HTTP/1.1 200 OK
content-type: text/plain; charset=UTF-8
server: envoy

LIVE
```

## Verify the Workload 

From your local machine, verify that the workload has been properly onboarded.

Execute the following command:

```bash{promptUser: "alice"}
kubectl get war -n bookinfo 
```

If the workload was properly onboarded, you should get an output similar to:

```bash{promptUser: "alice"}
NAMESPACE   NAME                                                              AGENT CONNECTED   AGE
bookinfo    ratings-aws-aws-123456789012-us-east-2b-ec2-i-1234567890abcdef0   True              1m
```

### Verify Traffic from Kubernetes to VM

To verify traffic from Kubernetes Pod(s) to AWS EC2 instance, create
some load on the bookinfo application deployed on Kubernetes and confirm
that requests get routed into the `ratings` application deployed on the
AWS EC2 instance.

On your local machine, [set up port forwarding](./bookinfo) if you have not already done so.

Then run the following commands:

```bash{promptUser: "alice"}
for i in `seq 1 9`; do
  curl -fsS "http://localhost:9080/productpage?u=normal" | grep "glyphicon-star" | wc -l | awk '{print $1" stars on the page"}'
done
```

Two out of three times you should get a message `10 stars on the page`.

Furthermore, you can verify that the VM is receiving the traffic by inspecting the 
[access logs](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)
for the incoming HTTP requests proxied by the Istio sidecar.

Execute the following command:

```bash{promptUser: "alice"}
journalctl -u onboarding-agent -o cat
```

You should see an output similar to:

```text
[2021-10-25T11:06:13.553Z] "GET /ratings/0 HTTP/1.1" 200 - via_upstream - "-" 0 48 3 2 "-" "curl/7.68.0" "1928e798-dfe7-45a6-9020-d0f3a8641d03" "172.31.7.211:9080" "127.0.0.1:9080" inbound|9080|| 127.0.0.1:40992 172.31.7.211:9080 172.31.7.211:35470 - default
```

### Verify Traffic from VM to Kubernetes

SSH into the AWS EC2 instance and execute the following commands:

```bash{promptUser: "alice"}
for i in `seq 1 5`; do
  curl -i \
    --resolve details.bookinfo:9080:127.0.0.2 \
    details.bookinfo:9080/details/0
done
```

The above command will make `5` HTTP requests to Bookinfo `details` application.
`curl` will resolve Kubernetes cluster-local DNS name `details.bookinfo`
into the IP address of the `egress` listener of Istio proxy (`127.0.0.2` according
to [the sidecar configuration you created earlier](./configure-workload-onboarding#create-the-sidecar-configuration)).

You should get an output similar to:

```bash{promptUser: "alice"}
HTTP/1.1 200 OK
content-type: application/json
server: envoy

{"id":0,"author":"William Shakespeare","year":1595,"type":"paperback",   "pages":200,"publisher":"PublisherA","language":"English",   "ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
```

---
title: Edge Gateway Introduction
---


# Introducing High Availability Clusters with Tetrate Edge Gateway

_This Design Guide explains how to configure a High Availability deployment that spans multiple workload clusters in multiple cloud regions_

Business-Critical and Large-Scale services may need to be deployed across two or more regions, for scalability and high-availability purposes.  This Design Guide explains how this can be achieved with Tetrate's Edge Gateway solution, which provides a front-end tier of highly-available load balancing proxies that accept traffic and forward them to workload clusters.

## Introducing Tetrate's Edge Gateway solution

There are several ways that administrators can configure their production environments to distribute traffic across two or more workload clusters.

### Common HA Patterns

For simple, small-scale deployments, several patterns are often seen:

 * **Global Server Load Balancing (GSLB)**.  With a GSLB system, each workload cluster is given a public endpoint (IP address), and DNS is used to control which endpoint a user is directed to.  The GSLB system performs health checks on each endpoint and takes failed clusters out-of-rotation, and it may also perform additional load-balancing measures such as proximity routing (send a client to the closest cluster) or load-based routing (send a client to the best-performing cluster).

 GSLB solutions most commonly use DNS to control how clients are assigned to data-centers.  DNS-based control has the disadvantage that clients and intermediate servers will cache DNS entries for a period of time, so failover or re-assignment is not immediate and clients may incur downtime as a result.

 * **Content-Delivery Network (CDN)**.  Many CDNs are capable of load-balancing traffic across two or more _origin_ servers, and provide a reliable, globally-distributed front-end for HTTP-based services.  A CDN-based configuration can be secured by configuring the origin servers to only accept traffic from the CDN PoPs (points of presence), and the CDN can then apply additional security measures such as volumetric DDoS prevention or web application firewalling.

 CDNs are best suited for web content that can be cached and distributed globally, where the administrator wishes to minimise the load on their origin servers and minimise page load time.  Many of the optimization capabilities of a CDN are not applicable to API or other dynamic content.

 * **Cloud-Based Load Balancers**.  When operating a single-vendor Cloud solution, you may wish to consider your cloud-providers solution for multi-regoin high availability.  Such solutions are often based on a combination of DNS manipulation (GSLB) and CDN-like proxies (e.g. AWS CloudFront), and they may offer the reliability, security and operational convenience that you require for your business-critical services.

### Tetrate Edge Gateway

Tetrate's Edge Gateway is a front-end proxy that is deployed to manage traffic and distribute it across multiple back-end workload clusters.  It is tightly-integrated into the Tetrate Management Plane, offering an effective and simple user experience, and scales to very large numbers of clusters, regions and levels of traffic.

In particular, the Edge Gateway deployment pattern:

 * **Supports both public and private IP addresses**, bridging from public to private if necessary.  An Edge Gateway deployment can reduce the number of public IP endpoints, which in turn reduces the attack surface and potentially the cost
 * **Consolidates the functionality of the workload cluster Ingress Gateway**, bringing it forward and closer to the client.  Performing rate limiting or authorization at the Edge reduces the load on the Workload clusters
 * **Secures the entire data-path**, from the very first Edge Gateway to the destination service, using Tetrate's mTLS and tunneling capabilities
 * **Can be optimized** to reduce failover time and eliminate unnecessary hops in a failover scenario

### Making the Edge Gateways highly-available

The Edge Gateway pattern is a two-tier pattern, where the Edge Gateways provide a first tier of load-balancing in front of a tier of Ingress Gateways in Workload clusters.

The Edge Gateways manage failover in the Workload clusters, and you can use any of the above solutions, such as a DNS-based GSLB solution, to manage the (less frequent) [edge-failover](failover of Edge Gateways).

## In this Design Guide

This design guide explains how to service critical services from multiple regions, with a configuration optimized for high availability and scalability.  The initial design for the solution brief uses the following architecture:

* Two separate cloud regions, potentially spanning multiple different cloud providers
* One ‘Edge Gateway’ receiving internet traffic
* Two ‘Workload Clusters’, one in each region, hosting the named service
* A single named service accessed through a single DNS name
* A third-party DNS service to distribute traffic to the Edge Gateway

Begin with the [Getting Started Documentation](demo-1) to create this example deployment.
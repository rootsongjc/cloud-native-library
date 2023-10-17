---
title: Promote a Service
draft: true
---

# Promote a Service from Development to Production

:::caution Need help on what to recommend to Platform Owners and App Owners...

Suggestions:

 * Use different Tetrate Workspaces for various tiers of dev/test/production
 * Use split DNS, so that (for example) 'database.myapp.svc.cluster.local' works without modification, but references a different database in each environment
   * Is this possible?  Is there a different way to apply runtime-configuration
 * Use different IngressGateways with different security postures (that cannot be overridden / set in the **Gateway** resource), restricting access
   * For example, on AWS, map dev and test to Internal load balancers, so are not internet accessible, or require unique authentication token for access
 
:::

## Platform Owner: Create workspaces with different security postures

What does the platform owner need to do?

## Application Owner: Deploy Service in a Production Workspace

Deploy service.  Manage external discovery e.g. DNS


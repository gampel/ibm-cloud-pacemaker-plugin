# IBM Cloud Pacemaker Plugin Wiki

Welcome to the IBM Cloud Pacemaker Plugin wiki! This wiki provides comprehensive documentation for the IBM Cloud Pacemaker Plugin, which enables high-availability cluster management for IBM Cloud VPC resources.

## Overview

The IBM Cloud Pacemaker Plugin extends Pacemaker's capabilities by adding support for managing IBM Cloud resources in Active-Passive mode. It provides seamless integration between IBM Cloud and the Pacemaker cluster resource manager, allowing you to manage cloud resources and deployment within Pacemaker.

## Table of Contents

1. [Getting Started](Getting-Started)
   - [Prerequisites](Getting-Started#prerequisites)
   - [Installation Guide](Getting-Started#installation-guide)
   - [Configuration](Getting-Started#configuration)

2. [Architecture](Architecture)
   - [System Components](Architecture#system-components)
   - [High Availability Setup](Architecture#high-availability-setup)
   - [Resource Types](Architecture#resource-types)

3. [Resource Agents](Resource-Agents)
   - [Custom Route VIP](Resource-Agents#custom-route-vip)
   - [Floating IP Failover](Resource-Agents#floating-ip-failover)
   - [Configuration Parameters](Resource-Agents#configuration-parameters)

4. [Cluster Configuration](Cluster-Configuration)
   - [Two-Node Setup](Cluster-Configuration#two-node-setup)
   - [Three-Node Quorum](Cluster-Configuration#three-node-quorum)
   - [Corosync Configuration](Cluster-Configuration#corosync-configuration)

5. [Security](Security)
   - [Authentication Methods](Security#authentication-methods)
   - [API Key Management](Security#api-key-management)
   - [Trusted Profile IAM](Security#trusted-profile-iam)

6. [Troubleshooting](Troubleshooting)
   - [Common Issues](Troubleshooting#common-issues)
   - [Log Analysis](Troubleshooting#log-analysis)
   - [Debugging Guide](Troubleshooting#debugging-guide)

7. [Best Practices](Best-Practices)
   - [Production Deployment](Best-Practices#production-deployment)
   - [Performance Optimization](Best-Practices#performance-optimization)
   - [Monitoring](Best-Practices#monitoring)

8. [API Reference](API-Reference)
   - [Resource Agent Parameters](API-Reference#resource-agent-parameters)
   - [Configuration Options](API-Reference#configuration-options)
   - [Environment Variables](API-Reference#environment-variables)

## Quick Links

- [GitHub Repository](https://github.com/gampel/ibm-cloud-pacemaker-plugin)
- [Issue Tracker](https://github.com/gampel/ibm-cloud-pacemaker-plugin/issues)
- [Contributing Guide](Contributing)
- [Release Notes](Release-Notes) 
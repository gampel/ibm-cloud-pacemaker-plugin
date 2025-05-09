# IBM Cloud Pacemaker Plugin

The IBM Cloud Pacemaker Plugin provides resource agents for managing IBM Cloud VPC resources in a Pacemaker cluster. This plugin enables high availability configurations for IBM Cloud VPC resources using Pacemaker's cluster management capabilities.

## Features

- Custom Route VIP resource agent for cross-zone high availability
- Floating IP Failover resource agent for same-zone high availability
- Integration with IBM Cloud VPC API
- Support for API key and Trusted Profile IAM authentication
- Compatible with standard Pacemaker cluster configurations

## Table of Contents

1. [Getting Started](Getting-Started.md)
   - Installation
   - Configuration
   - Basic Usage

2. [Architecture](Architecture.md)
   - System Components
   - High Availability Setup
   - Resource Management

3. [Resource Agents](Resource-Agents.md)
   - Custom Route VIP Agent
   - Floating IP Failover Agent
   - Configuration Options

4. [Cluster Configuration](Cluster-Configuration.md)
   - Two-Node Setup
   - Three-Node Quorum
   - Corosync Configuration

5. [Security](Security.md)
   - Authentication Methods
   - API Key Management
   - Security Best Practices

6. [Troubleshooting](Troubleshooting.md)
   - Common Issues
   - Log Analysis
   - Recovery Procedures

7. [Best Practices](Best-Practices.md)
   - Production Deployment
   - Performance Optimization
   - Monitoring

8. [API Reference](API-Reference.md)
   - Resource Agent Parameters
   - Configuration Options
   - Examples

9. [Contributing](Contributing.md)
   - Development Setup
   - Code Style
   - Testing
   - Pull Request Process

10. [Release Notes](Release-Notes.md)
    - Version History
    - Migration Guide
    - Known Issues

## Quick Links

- [GitHub Repository](https://github.com/gampel/ibm-cloud-pacemaker-plugin)
- [Issue Tracker](https://github.com/gampel/ibm-cloud-pacemaker-plugin/issues)
- [Contributing Guide](Contributing.md)
- [Release Notes](Release-Notes.md) 
# Getting Started

This guide will help you get started with the IBM Cloud Pacemaker Plugin. Follow these steps to set up and configure the plugin for your high-availability cluster.

## Prerequisites

Before you begin, ensure you have the following:

1. **IBM Cloud Account**
   - An active IBM Cloud account
   - Appropriate permissions to manage VPC resources
   - API key or Trusted Profile IAM token

2. **VPC Requirements**
   - VNI-based Virtual Network Interfaces pair for active-passive configuration
   - `allow_ip_spoofing` enabled on Virtual Network Interfaces
   - Instance Metadata enabled on VSI pairs
   - VPC API endpoint access (public or VPE)

3. **System Requirements**
   - Two or more Virtual Server Instances (VSIs)
   - For Floating IP Failover: VSIs must be in the same zone
   - For Custom Route VIP: VSIs can be in different zones
   - Sufficient system resources for Pacemaker and Corosync

4. **Software Requirements**
   - IBM Cloud VPC Python SDK
   - Pacemaker cluster resource manager
   - Corosync cluster engine
   - Python 3.6 or later
   - Make utility

## Installation Guide

### 1. Clone the Repository

```bash
git clone https://github.com/gampel/ibm-cloud-pacemaker-plugin.git
cd ibm-cloud-pacemaker-plugin
```

### 2. Install Dependencies

#### For Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install make python3-pip
```

#### For RHEL/CentOS:
```bash
sudo yum install make python3-pip
```

### 3. Install the Plugin

```bash
make install
```

This command will:
- Install all required dependencies
- Compile and install the resource agents
- Set up necessary configuration files

## Configuration

### 1. Basic Cluster Setup

1. Set password for `hacluster` user on all nodes:
```bash
passwd hacluster
```

2. Authenticate nodes:
```bash
pcs host auth node1 addr="<private_ip_node1>" node2 addr="<private_ip_node2>"
```

3. Create the cluster:
```bash
pcs cluster setup test_cluster node1 addr="<ip_node1>" node2 addr="<ip_node2>"
```

### 2. Configure Corosync

1. Start the cluster services:
```bash
sudo service corosync restart
systemctl restart pacemaker
systemctl enable pacemaker
```

2. Configure basic cluster properties:
```bash
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
```

### 3. Add Resources

#### Custom Route VIP Example:
```bash
pcs resource create ibm-cloud-vpc-cr-vip ocf:heartbeat:ibm-cloud-vpc-cr-vip \
    api_key="API_KEY" \
    ext_ip_1="IP_1" \
    ext_ip_2="IP_2" \
    vpc_url="https://eu-es.iaas.cloud.ibm.com/v1" \
    meta resource-stickiness=100 stonith-enabled=false \
    no-quorum-policy=ignore
```

#### Floating IP Failover Example:
```bash
pcs resource create floatingIpFailover ocf:heartbeat:ibm-cloud-vpc-move-fip \
    api_key="API_KEY" \
    vni_id_1="VNI_ID_1" \
    vni_id_2="VNI_ID_2" \
    fip_id="FIP_ID"
```

## Next Steps

- Review the [Architecture](Architecture.md) documentation to understand the system components
- Check [Best Practices](Best-Practices.md) for production deployment recommendations
- Explore [Troubleshooting](Troubleshooting.md) guide for common issues and solutions 
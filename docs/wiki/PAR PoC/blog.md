# IBM Cloud's Public Address Ranges: A Peacemaker Reference Implementation for High Availability

## Introduction

IBM Cloud's [Public Address Ranges](https://cloud.ibm.com/docs/vpc?topic=vpc-about-par) feature, combined with Pacemaker, serves two important purposes:
1. A reference implementation for firewall vendors to integrate their solutions with IBM Cloud
2. A production-ready solution for open-source high availability deployments

## Public Address Ranges Benefits for Customers

Public Address Ranges (PAR) is a powerful networking feature that allows customers to reserve and manage blocks of public IP addresses in IBM Cloud VPC. Here's what makes it special:

### Core Capabilities
- Reserve a public IP prefix up to /28 in size
- Assign the prefix to a specific VPC and zone
- Control traffic routing through custom routes in the public ingress table
- Move the prefix between zones within the same VPC for disaster recovery
- Transfer the prefix between VPCs in the same account
- Enable direct internet access for endpoints in the specified zone
- Support VM-level NAT to any IP in the PAR prefix
- Preserve original source IP for ingress traffic (no infrastructure NAT)

### 1. Multiple IP Management
- Reserve a continuous block of public IPs
- Simplified management of multiple public endpoints
- No need to manage individual floating IPs
- Flexible IP range sizes (/28 to /32)

### 2. Source IP Preservation
- Traffic maintains original source IP through the infrastructure
- No infrastructure NAT required
- Better visibility for security monitoring and logging
- Improved security analysis capabilities

### 3. Regional High Availability
- Zone-redundant public IP ranges
- Ability to move IPs between VPCs in different zones
- Disaster recovery support through zone migration
- Seamless failover capabilities

### 4. Security and Control
- Granular control over traffic flow
- Direct routing to security appliances
- No infrastructure NAT interference
- Better security monitoring capabilities
- VM-level NAT control
- Custom routing for ingress traffic

### 5. Network Architecture Benefits
- Simplified network design
- Reduced NAT complexity
- Better traffic visibility
- Enhanced security control
- Improved disaster recovery options
- Flexible routing control

## The Dual-Purpose Implementation

### 1. Reference Implementation for Vendors
This architecture demonstrates how to effectively integrate with IBM Cloud's Public Address Ranges feature, providing a blueprint for firewall vendors to:
- Implement zone-redundant high availability
- Handle failover scenarios while preserving source IPs
- Manage public ingress routing
- Integrate with IBM Cloud's networking features

### 2. Open Source High Availability Solution
For organizations looking to implement high availability using open-source FWs, this implementation provides:
- Production-ready Pacemaker configuration
- Cross-zone redundancy
- Automatic failover
- Source IP preservation

## Linux High Availability and Pacemaker

### Overview
Linux High Availability (HA) is a critical component for ensuring continuous service availability in enterprise environments. Pacemaker, as the cluster resource manager, provides:
- Automatic failover capabilities
- Resource monitoring and recovery
- Complex resource dependencies
- Support for multiple cluster topologies

For more information about Pacemaker and resource agents, visit the [ClusterLabs GitHub repository](https://github.com/ClusterLabs/resource-agents).

### Key Components
1. **Pacemaker**
   - Cluster resource manager
   - Handles resource allocation and failover
   - Manages service dependencies
   - Provides fencing mechanisms

2. **Corosync**
   - Cluster communication framework
   - Heartbeat and quorum management
   - Message ordering and delivery
   - Membership management

3. **Resource Agents**
   - Standard OCF resource agents
   - Systemd service management
   - Custom resource scripts
   - Health monitoring

## IBM Cloud Supported Plugins

### IBM Cloud Fail-over Package
The IBM Cloud Fail-over package ([ibm-cloud-fail-over](https://pypi.org/project/ibm-cloud-fail-over/1.0.8/)) is a Python-based abstraction layer for IBM Cloud plugins, providing a unified interface for high availability implementations. This package is designed to help Network Function Virtualization (NFV) vendors integrate their high availability solutions with IBM Cloud infrastructure. The Python implementation offers:

- Easy integration with existing Python-based systems
- Simple API for managing IBM Cloud resources
- Support for all IBM Cloud plugins (Custom Route, Floating IP, Public Address Ranges)
- Consistent interface across different high availability implementations
- Extensible architecture for custom plugin development

### Resource Agents
IBM Cloud provides several resource agents for Pacemaker integration, available in the [ClusterLabs resource-agents repository](https://github.com/ClusterLabs/resource-agents):

1. **Custom Route VIP Agent** ([ibm-cloud-vpc-cr-vip](https://github.com/ClusterLabs/resource-agents/blob/main/heartbeat/ibm-cloud-vpc-cr-vip.in))
   - Manages custom route-based virtual IPs
   - Handles route table updates for failover
   - Integrates with IBM Cloud VPC networking

2. **Floating IP Agent** ([ibm-cloud-vpc-move-fip](https://github.com/ClusterLabs/resource-agents/blob/main/heartbeat/ibm-cloud-vpc-move-fip.in))
   - Manages floating IP assignments
   - Handles IP movement between instances
   - Supports active-passive failover scenarios

3. **Public Address Ranges Plugin**
   - New implementation for Public Address Ranges management
   - Source IP preservation support
   - Zone-redundant configuration
   - Enhanced security features
   - Support for multiple endpoints
   - Currently in beta and available in the [IBM Cloud fork of resource-agents](https://github.com/gampel/resource-agents/tree/par_ibm_cloud_plugin)
   - Will be pushed to upstream ClusterLabs repository soon

### Integration Support for NFV Vendors
The IBM Cloud plugin architecture is designed to help NFV vendors:
- Implement high availability solutions
- Integrate with IBM Cloud infrastructure
- Manage network resources efficiently
- Handle failover scenarios
- Preserve source IP information
- Maintain service continuity

### Implementation Examples
1. **Custom Route Plugin**
   - Direct traffic routing to specific instances
   - Custom next-hop configuration
   - Zone-aware routing rules
   - Integration with security groups

2. **Floating IP Plugin**
   - Traditional floating IP management
   - Instance-level IP assignment
   - Basic failover capabilities
   - Limited to single IP management

3. **Public Address Ranges Plugin**
   - Block IP address management
   - Source IP preservation
   - Zone-redundant configuration
   - Enhanced security features
   - Support for multiple endpoints

## PoC Implementation: Public Address Ranges and Pacemaker Integration

### Purpose and Scope
This proof of concept demonstrates a production-ready implementation of public ingress traffic management using a highly available firewall appliance. The implementation uses Linux iptables as the firewall solution, protected by Pacemaker for high availability, and secures a web application tier. This approach provides:

1. **Public Ingress Protection**
   - Secure public access to internal services
   - Source IP preservation for security monitoring
   - Granular traffic control and filtering
   - High availability for continuous protection

2. **Firewall High Availability**
   - Active-Passive firewall deployment
   - Automatic failover with Pacemaker
   - State synchronization between nodes
   - Zero-downtime maintenance capability

3. **Web Tier Security**
   - Protected web application deployment
   - Controlled access through firewall
   - Load balancing capabilities
   - Health monitoring and recovery

### Architecture Design
The proof of concept demonstrates a production-ready implementation combining:
1. **High Availability Layer**
   - Active-Passive Pacemaker nodes
   - Quorum device for split-brain prevention
   - Cross-zone deployment
   - Automatic failover

2. **Network Layer**
   - Public Address Ranges for external access
   - Custom routing tables
   - Security group integration
   - NAT configuration

3. **Application Layer**
   - Web server deployment
   - Load balancing
   - Health monitoring
   - Service recovery

### Implementation Details

### Architecture Overview


```
flowchart TD
    Internet([Internet])
    PAR([Public Address Range (PAR)])
    PUBRT["PUBLIC Route Table<br/>Custom route:<br/>PAR prefix → Active FW (Pacemaker Node 1)"]
    
    subgraph FWLayer["Firewall Layer (Active/Passive)"]
        FW1["Pacemaker Node 1<br/>(au-syd-1)<br/>(Active)<br/>mgmt VNI, data VNI"]
        FW2["Pacemaker Node 2<br/>(au-syd-2)<br/>(Passive)<br/>mgmt VNI, data VNI"]
        Quorum["Quorum Device<br/>(au-syd-3)<br/>(Quorum)<br/>mgmt VNI, data VNI, [FIP]"]
    end

    subgraph AppLayer["Application Layer"]
        Web1["Web App 1<br/>(au-syd-1)<br/>VNI"]
        Web2["Web App 2<br/>(au-syd-2)<br/>VNI"]
    end

    Internet --> PAR
    PAR --> PUBRT
    PUBRT --> FWLayer
    FWLayer --> FW1
    FWLayer --> FW2
    FWLayer --> Quorum
    FW1 --> AppLayer
    FW2 --> AppLayer
    Quorum --> AppLayer
    AppLayer --> Web1
    AppLayer --> Web2
```


```
                                    Internet
                                        │
                                        ▼
                                Public Address Range (PAR)
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           PUBLIC Route Table                                 │
│  - Custom route: Public Address Ranges prefix → Active FW (Pacemaker Node 1) │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Firewall Layer (Active/Passive)                    │
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                       │
│  │ Pacemaker   │    │ Pacemaker   │    │ Quorum      │                       │
│  │ Node 1      │    │ Node 2      │    │ Device      │                       │
│  │ (au-syd-1)  │    │ (au-syd-2)  │    │ (au-syd-3)  │                       │
│  │  (Active)   │    │ (Passive)   │    │  (Quorum)   │                       │
│  │  mgmt VNI   │    │  mgmt VNI   │    │  mgmt VNI   │                       │
│  │  data VNI   │    │  data VNI   │    │  data VNI   │                       │
│  │             │    │             │    │  [FIP]      │                       │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                       │
│         │                  │                  │                              │
└─────────┼──────────────────┼──────────────────┼──────────────────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Application Layer                                    │
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐                                          │
│  │ Web App 1   │    │ Web App 2   │                                          │
│  │ (au-syd-1)  │    │ (au-syd-2)  │                                          │
│  │  VNI        │    │  VNI        │                                          │
│  └─────────────┘    └─────────────┘                                          │
└──────────────────────────────────────────────────────────────────────────────┘
```

Network Configuration:
- Firewall Subnets: 10.240.0.0/25 (AZ1), 10.240.1.0/25 (AZ2)
- Quorum Subnet: 10.240.2.0/25 (AZ3)
- App Subnets: 10.240.0.128/25 (AZ1), 10.240.1.128/25 (AZ2)
- Management Subnets: 10.250.0.0/24 (AZ1), 10.250.1.0/24 (AZ2), 10.250.2.0/24 (AZ3)
- Public Address Range (PAR) for external access
- Custom PUBLIC route table: PAR prefix → Active FW (Pacemaker Node 1)
- Floating IP on Quorum mgmt VNI
- Security groups for firewall and application layers

Traffic Flow:
- External traffic → PAR → PUBLIC Route Table → Active Pacemaker Node
- Active Node → NAT → Web Application
- Failover: Active Node → Passive Node → Web Application
- Quorum device accessible via Floating IP for management

## PoC Deployment and Testing

### Deployment Steps

1. **Infrastructure Setup with Terraform**
   ```bash
   # Set global IBM Cloud API key (recommended)
   export IC_API_KEY="your-api-key"
   
   # Update terraform.tfvars with your values
   # Note: It's better to use the global IC_API_KEY environment variable
   # instead of setting the API key in terraform.tfvars for better security
   resource_group = "your-resource-group"
   ssh_key        = "your-ssh-key-name"
   # ibmcloud_api_key = "your-api-key"  # Not recommended to set here
   ```

   Using a global API key variable (`IC_API_KEY`) is recommended because:
   - Prevents accidental commit of sensitive credentials to version control
   - Follows security best practices for credential management
   - Makes it easier to rotate API keys without modifying Terraform files
   - Works across multiple Terraform projects
   - Can be set in CI/CD pipelines securely

   ```bash
   # Initialize and apply Terraform
   terraform init
   terraform plan
   terraform apply
   ```

   > **Note:** Since Terraform support for Public Address Ranges (PAR) is not yet available, you'll need to manually:
   > 1. Create a Public Address Range in your VPC and attach it to zone 1
   > 2. Create a route in the public ingress routing table with:
   >    - Destination: Your PAR CIDR block
   >    - Next hop: The eth0 interface IP of FW1 VM
   > This route will be managed by the Pacemaker cluster during failover scenarios.
   
   >use the PAR prefix as the VIP and set it in the  follwing where mentioned PAR_VIP_IP 

2. **Firewall Node Installation**

   After Terraform deployment, two environment files are generated:
   - `fw_install_params.env`: Contains firewall and quorum device parameters
   - `web_install_params.env`: Contains web application parameters

   These files contain the following variables:
   ```bash
   # fw_install_params.env
   QUORUM_FIP="<quorum-device-floating-ip>"
   FW1_MGMT_IP="<firewall-1-management-ip>"
   FW2_MGMT_IP="<firewall-2-management-ip>"

   # web_install_params.env
   WEB_APP_1_IP="<web-app-1-ip>"
   WEB_APP_2_IP="<web-app-2-ip>"
   ```

   Access Pattern:
   - Only the Quorum device has a Floating IP (FIP) for management access
   - All other nodes use Public Gateway (PGW) for egress traffic
   - Use the Quorum device as a jump host to access other nodes

   ```bash
   # Source the environment file
   source fw_install_params.env

   # First, SSH to the Quorum device
   ssh root@$QUORUM_FIP
   
  you can use SSH jump host feature to access the fw and web VMs:
   ```bash
   # SSH to firewall node 1 through Quorum device
   ssh -A -J root@$QUORUM_FIP root@$FW1_MGMT_IP
   ```

   # Run the installation script, it will copy and execute that script on the two FW nodes 
   ```bash
   # Make the script executable
   chmod +x install_fw_remote.sh
   
   # Run the installation script with the PAR VIP IP
   # The script will:
   # 1. Copy setup-pacemaker.sh to both firewall nodes
   # 2. Copy web_install_params.env to both firewall nodes
   # 3. Execute setup-pacemaker.sh on both nodes with the PAR VIP IP
   ./install_fw_remote.sh setup-pacemaker.sh <PAR_VIP_IP>
   ```

   The firewall nodes are responsible for handling the traffic routing and NAT configuration. The setup is done automatically via the installation script (`setup-pacemaker.sh`), which configures the following:

   1. **Network Configuration**:
      - Sets up NAT for traffic forwarding
      - Configures port forwarding for web traffic (ports 80 and 443)
      - Sets the PAR VIP as a secondary IP on eth0
      - Configures iptables rules for traffic management

   2. **High Availability Setup**:
      - Installs and configures Pacemaker and Corosync
      - Sets up the cluster with proper fencing
      - Configures resource monitoring

   3. **Persistence**:
      - Saves iptables rules to `/etc/iptables/rules.v4`
      - Configures `rc.local` to restore rules on boot
      - Sets up health monitoring via cron

   The following sections explain what the installation script configures on the firewall devices:

   ### Network Configuration

   The script automatically configures:

   1. **NAT and Port Forwarding**:
      ```bash
      # Configure NAT
      echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
      sysctl -p

      # Configure NAT rules
      iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

      # Configure port forwarding for web traffic
      iptables -t nat -A PREROUTING -i eth0 -p tcp -d $PAR_VIP_IP --dport 80 -j DNAT --to-destination $WEB_VIP
      iptables -t nat -A PREROUTING -i eth0 -p tcp -d $PAR_VIP_IP --dport 443 -j DNAT --to-destination $WEB_VIP
      ```

   2. **Traffic Rules**:
      ```bash
      # Allow web traffic in FORWARD chain
      iptables -A FORWARD -i eth0 -p tcp -d $WEB_VIP --dport 80 -j ACCEPT
      iptables -A FORWARD -i eth0 -p tcp -d $WEB_VIP --dport 443 -j ACCEPT
      iptables -A FORWARD -i eth1 -p tcp -d $WEB_VIP --dport 80 -j ACCEPT
      iptables -A FORWARD -i eth1 -p tcp -d $WEB_VIP --dport 443 -j ACCEPT

      # Allow web traffic in INPUT chain
      iptables -A INPUT -p tcp --dport 80 -j ACCEPT
      iptables -A INPUT -p tcp --dport 443 -j ACCEPT
      ```

   3. **PAR VIP Configuration**:
      ```bash
      # Set PAR VIP as source IP for eth0
      ip addr add $PAR_VIP_IP/32 dev eth0
      echo "ip addr add $PAR_VIP_IP/32 dev eth0" >> /etc/rc.d/rc.local
      ```

   ### High Availability Setup

   The script configures:

   1. **Pacemaker and Corosync**:
      ```bash
      # Install required packages
      yum install -y pacemaker pcs corosync fence-agents-all iptables-services

      # Enable and start services
      systemctl enable --now pcsd
      systemctl enable --now corosync
      systemctl enable --now pacemaker
      ```
 
   ### Persistence Configuration

   The script ensures all configurations persist across reboots:

   1. **Iptables Rules**:
      ```bash
      # Save iptables rules
      iptables-save > /etc/iptables/rules.v4

      # Create rc.local if it doesn't exist
      if [ ! -f /etc/rc.d/rc.local ]; then
          touch /etc/rc.d/rc.local
          chmod +x /etc/rc.d/rc.local
      fi

      # Add iptables restore command to rc.local
      echo "iptables-restore < /etc/iptables/rules.v4" >> /etc/rc.d/rc.local
      ```

   2. **Service Persistence**:
      ```bash
      # Enable rc.local service
      systemctl enable rc-local
      systemctl start rc-local
      ```

   These configurations are automatically applied when you run the installation script. You don't need to manually configure any of these settings.

3. **Web Application Installation**
   ```bash
   # Source the environment file
   source web_install_params.env

   # SSH to web app 1 through Quorum device
   ssh -A -J root@$QUORUM_FIP root@$WEB_APP_1_IP
   
   # Copy installation scripts
   scp install_web_remote.sh setup-web-server.sh root@$WEB_APP_1_IP:~/
   
   # Run the installation script
   chmod +x install_web_remote.sh
   ./install_web_remote.sh setup-web-server.sh
   ```

   > **Note:** The firewall configuration (NAT, port forwarding, and PAR VIP setup) is automatically handled by the `setup-pacemaker.sh` script during the firewall node installation. You don't need to manually configure these settings.

# Setting up a High Availability Cluster with Pacemaker for Public Address Ranges

## Overview
This guide demonstrates how to set up a high availability cluster using Pacemaker specifically for managing IBM Cloud Public Address Ranges (PAR). The cluster will be configured to handle failover scenarios while preserving source IP addresses and ensuring continuous service availability.

## Prerequisites
- Two RHEL 8 firewall nodes (pacemaker-node-1 and pacemaker-node-2)
- One RHEL 8 quorum device node
- Network connectivity between nodes
- Root access to all nodes
- Hostnames configured in /etc/hosts
- IBM Cloud API key
- Public Address Ranges ID
- Custom route external IPs
- Environment variables set from fw_install_params.env

## Installation Steps

> **Note:** The following installation steps are automatically handled by the installation scripts provided in this repository. You don't need to manually execute these commands unless you're doing a custom installation.

### 3. Configure Cluster Nodes

#### 3.1 Set up hacluster user
On both firewall nodes (pacemaker-node-1 and pacemaker-node-2), set the hacluster password:
```bash
echo "hacluster:hacluster" | chpasswd
```

#### 3.2 Start and enable pcsd
On both firewall nodes:
```bash
systemctl enable --now pcsd
```

#### 3.3 Authenticate nodes
On pacemaker-node-1:
```bash
pcs auth -u hacluster -p hacluster pacemaker-node-1 pacemaker-node-2
```

#### 3.4 Create the cluster
On pacemaker-node-1:
```bash
pcs cluster setup --name par-cluster pacemaker-node-1 pacemaker-node-2
```

#### 3.5 Start the cluster
On pacemaker-node-1:
```bash
pcs cluster start --all
```

### 4. Configure Quorum Device (Required for PAR Implementation)

#### 4.1 Install quorum device package
On both firewall nodes (pacemaker-node-1 and pacemaker-node-2):
```bash
yum install -y corosync-qdevice
```

#### 4.2 Set up quorum device
On the quorum device node:
```bash
yum install -y corosync-qnetd
systemctl enable --now corosync-qnetd
```

#### 4.3 Authenticate quorum device
On both firewall nodes (pacemaker-node-1 and pacemaker-node-2):
```bash
# Authenticate with the quorum device
pcs host auth $QUORUM_MGMT_IP
```

#### 4.4 Configure quorum device in the cluster
On both firewall nodes (pacemaker-node-1 and pacemaker-node-2):
```bash
# Generate certificates
pcs qdevice setup model net --enable --start

# Add the quorum device to the cluster
pcs quorum device add model net host=$QUORUM_MGMT_IP algorithm=ffsplit
```

#### 4.5 Verify quorum device status
On the quorum device node:
```bash
pcs qdevice status net --full
```

On either firewall node:
```bash
pcs quorum device status
pcs quorum status
```

#### 4.6 Managing the quorum device service
On the quorum device node, you can manage the service with these commands:
```bash
# Start the quorum device service
pcs qdevice start net

# Stop the quorum device service
pcs qdevice stop net

# Enable the quorum device service
pcs qdevice enable net

# Disable the quorum device service
pcs qdevice disable net

# Kill the quorum device service
pcs qdevice kill net
```

#### 4.7 Managing quorum device in cluster
On either firewall node:
```bash
# Update quorum device settings
pcs quorum device update model algorithm=lms

# Remove quorum device
pcs quorum device remove

# Destroy quorum device (on quorum device node)
pcs qdevice destroy net
```

### 5. Configure IBM Cloud Public Address Ranges

#### 5.1 Configure Public Address Range (PAR)
Create the PAR resource in the cluster:
```bash
pcs resource create ibm-cloud-vpc-par ocf:heartbeat:ibm-cloud-vpc-par \
    api_key="API_KEY" \
    address_prefix_range_id="r026-<your-address-range-id>" \
    next_hop_ip_1="<fw1-data-ip>" \
    next_hop_ip_2="<fw2-data-ip>" \
    vpc_url="https://au-syd.private.iaas.cloud.ibm.com" \
    meta resource-stickiness=100 stonith-enabled=false \
    no-quorum-policy=ignore
```

Note: Replace `<your-address-range-id>` with your actual Public Address Ranges ID. The format should be `r026-<uuid>` where `r026` is the region identifier and `<uuid>` is your unique address range ID. Also replace `<fw1-data-ip>` and `<fw2-data-ip>` with the data interface IP addresses of your firewall nodes.

### 6. Verify Cluster Status
```bash
pcs status
pcs cluster status
```

## Testing the PAR Cluster

### 1. Test Resource Failover
```bash
# Move the PAR resource to a specific node
pcs resource move ibm-cloud-vpc-par pacemaker-node-2

# Check resource location
pcs resource show
```

### 2. Test Node Failure
```bash
# Simulate node failure
pcs node standby pacemaker-node-1

# Verify failover
pcs status
```

## Troubleshooting

### Common Issues and Solutions

1. **Authentication Failures**
   - Verify hacluster password is set correctly
   - Check /etc/hosts for correct hostname resolution
   - Ensure pcsd is running on all nodes

2. **Quorum Issues**
   - Check quorum device status
   - Verify network connectivity between nodes
   - Check corosync logs: `journalctl -u corosync`

3. **PAR Resource Failures**
   - Check resource logs: `pcs resource debug-start ibm-cloud-vpc-par`
   - Verify PAR configuration
   - Check system logs for errors

### Useful Commands

```bash
# View cluster status
pcs status

# View detailed cluster configuration
pcs config

# View corosync configuration
pcs corosync config

# View resource status
pcs resource show

# View node status
pcs node status
```

## References
- [Red Hat High Availability Add-On Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_high_availability_clusters/index)
- [Pacemaker Documentation](https://clusterlabs.org/pacemaker/doc/)
- [Corosync Documentation](https://corosync.github.io/corosync/)
- [IBM Cloud Public Address Ranges Documentation](https://cloud.ibm.com/docs/vpc?topic=vpc-about-par)
- [IBM Cloud Fail-over Package](https://pypi.org/project/ibm-cloud-fail-over/1.0.8/) - Python-based abstraction layer for IBM Cloud plugins

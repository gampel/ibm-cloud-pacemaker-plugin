# PAR PoC Architecture (Updated)

## High Availability Pacemaker Cluster with Web Application

```
                                    Internet
                                        │
                                        ▼
                                Public Address Range (PAR)
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           PUBLIC Route Table                                 │
│  - Custom route: PAR prefix → Active FW (Pacemaker Node 1)                   │
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

Network Configuration:
- Firewall Subnets: 10.240.0.0/25 (AZ1), 10.240.1.0/25 (AZ2)
- Quorum Subnet: 10.240.2.0/25 (AZ3)
- App Subnets: 10.240.0.128/25 (AZ1), 10.240.1.128/25 (AZ2)
- Management Subnets: 10.250.0.0/24 (AZ1), 10.250.1.0/24 (AZ2), 10.250.2.0/24 (AZ3)
- Public Address Range (PAR) for external access
- Custom PUBLIC route table: PAR prefix → Active FW (Pacemaker Node 1)
- Floating IP on Quorum mgmt VNI
- Security groups for firewall and application layers

Components:
1. Firewall Layer:
   - 2 Pacemaker nodes (Active/Passive, each with mgmt and data VNIs)
   - 1 Quorum device (mgmt and data VNIs, mgmt VNI has FIP)
   - Public Address Range (PAR) for external access
   - iptables for NAT and security
   - Custom PUBLIC route table for PAR

2. Application Layer:
   - 2 Web applications (each with a VNI)
   - Apache with PHP support
   - Separate security group
   - Private subnet access only

3. High Availability Features:
   - Active-Passive configuration
   - Cross-zone deployment
   - Quorum device for split-brain prevention
   - Automatic failover
   - Load balancing through NAT

4. Security:
   - Restricted SSH access
   - Firewall rules for required ports
   - NAT for secure traffic forwarding
   - Separate security groups for layers

5. Traffic Flow:
   - External traffic → PAR → PUBLIC Route Table → Active Pacemaker Node
   - Active Node → NAT → Web Application
   - Failover: Active Node → Passive Node → Web Application
   - Quorum device accessible via Floating IP for management
``` 
# Architecture

This page describes the architecture of the IBM Cloud Pacemaker Plugin and its integration with IBM Cloud VPC.

## System Components

The IBM Cloud Pacemaker Plugin consists of the following main components:

1. **Resource Agents**
   - Custom Route VIP Agent
   - Floating IP Failover Agent
   - OCF-compliant resource agents

2. **IBM Cloud Integration**
   - VPC API Client
   - Authentication Handler
   - Resource Manager

3. **Cluster Management**
   - Pacemaker Integration
   - Corosync Communication
   - Resource State Management

## High Availability Setup

### Active-Passive Configuration

The plugin supports two types of high availability configurations:

1. **Same-Zone HA**
   - Nodes in the same availability zone
   - Floating IP failover
   - Low-latency failover

2. **Cross-Zone HA**
   - Nodes in different availability zones
   - Custom Route VIP
   - Zone-level redundancy

### Resource Management

The plugin manages resources in an active-passive configuration:

1. **Active Node**
   - Primary resource owner
   - Handles all resource operations
   - Monitors resource health

2. **Passive Node**
   - Standby resource owner
   - Ready for failover
   - Maintains synchronization

## Resource Types

### Custom Route VIP

- Supports cross-zone high availability
- Uses IBM Cloud Custom Routes
- Provides zone-level redundancy
- Suitable for multi-zone deployments

### Floating IP Failover

- Supports same-zone high availability
- Uses IBM Cloud Floating IPs
- Provides instance-level redundancy
- Suitable for single-zone deployments

## System Architecture

```
+------------------+     +------------------+
|   Active Node    |     |  Passive Node    |
|  +------------+  |     |  +------------+  |
|  | Pacemaker  |  |     |  | Pacemaker  |  |
|  +------------+  |     |  +------------+  |
|  | Resource   |  |     |  | Resource   |  |
|  | Agent      |  |     |  | Agent      |  |
|  +------------+  |     |  +------------+  |
+------------------+     +------------------+
         |                       |
         v                       v
+------------------------------------------+
|           IBM Cloud VPC API              |
+------------------------------------------+
```

## Communication Flow

1. **Resource Monitoring**
   - Active node monitors resource health
   - Reports status to Pacemaker
   - Triggers failover if needed

2. **Failover Process**
   - Detects node failure
   - Promotes passive node
   - Updates resource ownership
   - Reconfigures network

3. **State Synchronization**
   - Maintains resource state
   - Synchronizes configuration
   - Ensures consistency

## Integration Points

### IBM Cloud VPC

- VPC API endpoints
- Resource management
- Network configuration
- Authentication

### Pacemaker

- Resource management
- Cluster coordination
- Health monitoring
- Failover control

### Corosync

- Cluster communication
- Node membership
- Quorum management
- State synchronization 
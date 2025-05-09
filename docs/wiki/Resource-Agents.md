# Resource Agents

This page documents the available resource agents in the IBM Cloud Pacemaker Plugin and their configuration options.

## Custom Route VIP

The Custom Route VIP resource agent provides high availability for applications using IBM Cloud Custom Routes. It supports both same-zone and cross-zone high availability configurations.

### Features
- Active-passive failover between nodes
- Support for same-zone and cross-zone deployments
- Automatic failover on node failure
- Configurable failback behavior

### Configuration Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `api_key` | No* | IBM Cloud API key for authentication |
| `ext_ip_1` | Yes | Private IP address of the first VSI |
| `ext_ip_2` | Yes | Private IP address of the second VSI |
| `vpc_url` | Yes | VPC API endpoint URL (public or VPE) |

*Required if not using Trusted Profile IAM

### Example Configuration

```bash
pcs resource create ibm-cloud-vpc-cr-vip ocf:heartbeat:ibm-cloud-vpc-cr-vip \
    api_key="API_KEY" \
    ext_ip_1="10.0.0.1" \
    ext_ip_2="10.0.0.2" \
    vpc_url="https://eu-es.iaas.cloud.ibm.com/v1" \
    meta resource-stickiness=100
```

## Floating IP Failover

The Floating IP Failover resource agent manages the failover of IBM Cloud VPC Floating IPs between nodes in the same availability zone.

### Features
- Active-passive failover within the same availability zone
- Automatic failover on node failure
- Support for multiple network interfaces
- Configurable failback behavior

### Configuration Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `api_key` | No* | IBM Cloud API key for authentication |
| `vni_id_1` | Yes | VNI ID of the first node's network interface |
| `vni_id_2` | Yes | VNI ID of the second node's network interface |
| `fip_id` | Yes | Floating IP ID to be managed |

*Required if not using Trusted Profile IAM

### Example Configuration

```bash
pcs resource create floatingIpFailover ocf:heartbeat:ibm-cloud-vpc-move-fip \
    api_key="API_KEY" \
    vni_id_1="02w7-afc89131-7901-4603-848a-5488680c683d" \
    vni_id_2="02w7-c0f2ff9b-3128-4d91-ab32-7d612659867d" \
    fip_id="r050-f0e45301-f07d-4117-86b7-dd0ea60e5b9f"
```

## Resource Agent Operations

Both resource agents support the following standard Pacemaker operations:

| Operation | Description |
|-----------|-------------|
| `start` | Start the resource on the current node |
| `stop` | Stop the resource on the current node |
| `monitor` | Check the resource status |
| `promote` | Promote the resource to active state |
| `demote` | Demote the resource to passive state |

### Operation Timeouts

Default operation timeouts can be modified using the `op` parameter:

```bash
pcs resource create ibm-cloud-vpc-cr-vip ocf:heartbeat:ibm-cloud-vpc-cr-vip \
    ... \
    op monitor interval=30s timeout=20s \
    op start timeout=60s \
    op stop timeout=60s
```

## Resource Constraints

### Location Constraints

Control which nodes can run the resource:

```bash
pcs constraint location ibm-cloud-vpc-cr-vip prefers node1=100
```

### Order Constraints

Define the order of resource operations:

```bash
pcs constraint order start resource1 then start ibm-cloud-vpc-cr-vip
```

### Colocation Constraints

Keep resources together:

```bash
pcs constraint colocation add ibm-cloud-vpc-cr-vip with resource1
```

## Monitoring and Maintenance

### Resource Status

Check resource status:

```bash
pcs resource show ibm-cloud-vpc-cr-vip
```

### Resource Cleanup

Clean up resource state:

```bash
pcs resource cleanup ibm-cloud-vpc-cr-vip
```

### Resource Management

Move resource to another node:

```bash
pcs resource move ibm-cloud-vpc-cr-vip node2
```

Ban resource from a node:

```bash
pcs resource ban ibm-cloud-vpc-cr-vip node1
```

## Best Practices

1. Always use resource stickiness to control failback behavior
2. Configure appropriate timeouts for your environment
3. Use constraints to control resource placement
4. Monitor resource status regularly
5. Test failover scenarios in a controlled environment 
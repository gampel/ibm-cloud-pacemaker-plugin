# API Reference

This page provides detailed reference information for the IBM Cloud Pacemaker Plugin API and configuration options.

## Resource Agent Parameters

### Custom Route VIP Agent

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `api_key` | string | No* | - | IBM Cloud API key |
| `ext_ip_1` | string | Yes | - | First node's IP address |
| `ext_ip_2` | string | Yes | - | Second node's IP address |
| `vpc_url` | string | Yes | - | VPC API endpoint URL |

*Required if not using Trusted Profile IAM

### Floating IP Failover Agent

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `api_key` | string | No* | - | IBM Cloud API key |
| `vni_id_1` | string | Yes | - | First node's VNI ID |
| `vni_id_2` | string | Yes | - | Second node's VNI ID |
| `fip_id` | string | Yes | - | Floating IP ID |

*Required if not using Trusted Profile IAM

## Configuration Options

### Resource Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resource-stickiness` | integer | 0 | Resource stickiness value |
| `stonith-enabled` | boolean | true | STONITH enabled flag |
| `no-quorum-policy` | string | stop | No quorum policy |

### Operation Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `interval` | time | 30s | Operation interval |
| `timeout` | time | 20s | Operation timeout |
| `on-fail` | string | stop | Failure action |

## Environment Variables

### Authentication

| Variable | Description |
|----------|-------------|
| `IBMCLOUD_API_KEY` | IBM Cloud API key |
| `IBMCLOUD_IAM_TOKEN` | IAM token for trusted profiles |

### API Configuration

| Variable | Description |
|----------|-------------|
| `IBMCLOUD_VPC_URL` | VPC API endpoint URL |
| `IBMCLOUD_REGION` | IBM Cloud region |

## Resource Agent Operations

### Standard Operations

| Operation | Description | Parameters |
|-----------|-------------|------------|
| `start` | Start resource | - |
| `stop` | Stop resource | - |
| `monitor` | Monitor resource | interval, timeout |
| `promote` | Promote resource | - |
| `demote` | Demote resource | - |

### Operation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `interval` | time | 30s | Operation interval |
| `timeout` | time | 20s | Operation timeout |
| `on-fail` | string | stop | Failure action |

## Resource Constraints

### Location Constraints

```bash
pcs constraint location <resource> prefers <node>=<score>
```

### Order Constraints

```bash
pcs constraint order <action> <resource1> then <action> <resource2>
```

### Colocation Constraints

```bash
pcs constraint colocation add <resource1> with <resource2>
```

## Resource Properties

### Common Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `is-managed` | boolean | true | Resource management flag |
| `target-role` | string | Started | Target role |
| `priority` | integer | 0 | Resource priority |

### Resource-Specific Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `stickiness` | integer | 0 | Resource stickiness |
| `migration-threshold` | integer | 0 | Migration threshold |

## Error Handling

### Common Errors

| Error Code | Description | Resolution |
|------------|-------------|------------|
| `OCF_ERR_CONFIGURED` | Configuration error | Check parameters |
| `OCF_ERR_PERM` | Permission error | Check permissions |
| `OCF_ERR_ARGS` | Invalid arguments | Check arguments |

### Error Recovery

1. **Configuration Errors**
   - Verify parameters
   - Check syntax
   - Validate values

2. **Permission Errors**
   - Check API key
   - Verify IAM roles
   - Check permissions

3. **Resource Errors**
   - Check resource state
   - Verify configuration
   - Check dependencies

## Examples

### Basic Resource Creation

```bash
pcs resource create ibm-cloud-vpc-cr-vip ocf:heartbeat:ibm-cloud-vpc-cr-vip \
    api_key="API_KEY" \
    ext_ip_1="10.0.0.1" \
    ext_ip_2="10.0.0.2" \
    vpc_url="https://eu-es.iaas.cloud.ibm.com/v1"
```

### Resource with Options

```bash
pcs resource create ibm-cloud-vpc-cr-vip ocf:heartbeat:ibm-cloud-vpc-cr-vip \
    api_key="API_KEY" \
    ext_ip_1="10.0.0.1" \
    ext_ip_2="10.0.0.2" \
    vpc_url="https://eu-es.iaas.cloud.ibm.com/v1" \
    meta resource-stickiness=100 \
    op monitor interval=30s timeout=20s
```

### Resource with Constraints

```bash
pcs constraint location ibm-cloud-vpc-cr-vip prefers node1=100
pcs constraint order start resource1 then start ibm-cloud-vpc-cr-vip
pcs constraint colocation add ibm-cloud-vpc-cr-vip with resource1
``` 
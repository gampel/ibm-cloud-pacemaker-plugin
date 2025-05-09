# Troubleshooting

This page provides guidance for troubleshooting common issues with the IBM Cloud Pacemaker Plugin.

## Common Issues

### Cluster Communication Issues

1. **Symptoms**
   - Nodes not communicating
   - Split-brain scenarios
   - Resource failover failures

2. **Diagnosis**
   ```bash
   # Check cluster status
   pcs status
   
   # Check Corosync status
   corosync-cfgtool -s
   
   # Check network connectivity
   ping <node_ip>
   ```

3. **Solutions**
   - Verify network connectivity
   - Check firewall rules
   - Review Corosync configuration
   - Check node authentication

### Resource Failures

1. **Symptoms**
   - Resources not starting
   - Unexpected failovers
   - Resource state inconsistencies

2. **Diagnosis**
   ```bash
   # Check resource status
   pcs resource show
   
   # Check resource logs
   pcs resource debug-start <resource>
   
   # Check resource configuration
   pcs resource show <resource>
   ```

3. **Solutions**
   - Verify resource configuration
   - Check permissions
   - Review resource logs
   - Clean up resource state

### Authentication Issues

1. **Symptoms**
   - API access failures
   - Authentication errors
   - Permission denied errors

2. **Diagnosis**
   ```bash
   # Check API key
   pcs resource show <resource> | grep api_key
   
   # Test API access
   curl -H "Authorization: Bearer $API_KEY" $VPC_URL
   ```

3. **Solutions**
   - Verify API key validity
   - Check permissions
   - Update authentication method
   - Review IAM settings

## Log Analysis

### Important Log Files

1. **Pacemaker Logs**
   - Location: `/var/log/pacemaker/pacemaker.log`
   - Contains: Cluster operations, resource management
   - Analysis: Look for errors, warnings, state changes

2. **Corosync Logs**
   - Location: `/var/log/corosync/corosync.log`
   - Contains: Cluster communication, node status
   - Analysis: Check for communication issues, node failures

3. **Resource Agent Logs**
   - Location: `/var/log/messages`
   - Contains: Resource operations, API calls
   - Analysis: Review resource operations, API responses

### Log Analysis Tools

1. **Pacemaker Tools**
   ```bash
   # Show cluster status
   pcs status
   
   # Show resource history
   pcs resource history show <resource>
   
   # Show cluster configuration
   pcs config
   ```

2. **Corosync Tools**
   ```bash
   # Show Corosync status
   corosync-cfgtool -s
   
   # Show node status
   corosync-cmapctl | grep members
   ```

3. **System Tools**
   ```bash
   # Check system logs
   journalctl -u pacemaker
   journalctl -u corosync
   
   # Check resource agent logs
   tail -f /var/log/messages
   ```

## Debugging Guide

### Basic Debugging Steps

1. **Cluster Status**
   ```bash
   # Check overall status
   pcs status
   
   # Check node status
   pcs node status
   
   # Check resource status
   pcs resource status
   ```

2. **Configuration Verification**
   ```bash
   # Verify cluster configuration
   pcs config
   
   # Verify resource configuration
   pcs resource show
   
   # Verify constraints
   pcs constraint show
   ```

3. **Resource Debugging**
   ```bash
   # Debug resource start
   pcs resource debug-start <resource>
   
   # Monitor resource
   pcs resource monitor <resource>
   
   # Clean up resource
   pcs resource cleanup <resource>
   ```

### Advanced Debugging

1. **Cluster Debugging**
   ```bash
   # Enable debug logging
   pcs property set debug=true
   
   # Show cluster properties
   pcs property list
   
   # Check cluster communication
   corosync-cfgtool -s
   ```

2. **Resource Debugging**
   ```bash
   # Enable resource debugging
   pcs resource debug-monitor <resource>
   
   # Show resource history
   pcs resource history show <resource>
   
   # Check resource operations
   pcs resource operations <resource>
   ```

3. **Network Debugging**
   ```bash
   # Check network connectivity
   ping <node_ip>
   
   # Check port availability
   netstat -an | grep 5405
   
   # Check firewall rules
   iptables -L
   ```

## Recovery Procedures

### Cluster Recovery

1. **Node Recovery**
   ```bash
   # Start node
   pcs cluster start <node>
   
   # Enable node
   pcs cluster enable <node>
   
   # Check node status
   pcs node status
   ```

2. **Resource Recovery**
   ```bash
   # Clean up resource
   pcs resource cleanup <resource>
   
   # Restart resource
   pcs resource restart <resource>
   
   # Verify resource status
   pcs resource show <resource>
   ```

3. **Configuration Recovery**
   ```bash
   # Restore configuration
   pcs cluster cib-push <backup_file>
   
   # Verify configuration
   pcs config
   
   # Apply changes
   pcs cluster reload
   ```

### Data Recovery

1. **Backup Procedures**
   - Regular configuration backups
   - Resource state backups
   - Node configuration backups

2. **Restore Procedures**
   - Restore from backups
   - Verify configurations
   - Test functionality

3. **Verification Steps**
   - Check cluster status
   - Verify resource states
   - Test failover scenarios 
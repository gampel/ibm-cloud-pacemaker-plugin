# Cluster Configuration

This page provides detailed instructions for configuring your Pacemaker cluster with the IBM Cloud Pacemaker Plugin.

## Two-Node Setup

### Prerequisites

1. Two Virtual Server Instances (VSIs)
2. Network connectivity between nodes
3. IBM Cloud API access
4. Required permissions for VPC resources

### Basic Configuration

1. **Install Required Software**
   ```bash
   # On both nodes
   sudo apt-get update
   sudo apt-get install pacemaker corosync pcs
   ```

2. **Configure Hosts**
   ```bash
   # On both nodes
   sudo vi /etc/hosts
   # Add entries for both nodes
   10.0.0.1 node1
   10.0.0.2 node2
   ```

3. **Set Up Authentication**
   ```bash
   # On both nodes
   sudo passwd hacluster
   
   # On node1
   pcs host auth node1 node2
   ```

4. **Create Cluster**
   ```bash
   # On node1
   pcs cluster setup mycluster node1 node2
   pcs cluster start --all
   pcs cluster enable --all
   ```

5. **Configure Cluster Properties**
   ```bash
   pcs property set stonith-enabled=false
   pcs property set no-quorum-policy=ignore
   ```

## Three-Node Quorum

### Prerequisites

1. Three Virtual Server Instances
2. Network connectivity between all nodes
3. Quorum device (optional but recommended)

### Configuration Steps

1. **Basic Setup**
   ```bash
   # On all nodes
   pcs host auth node1 node2 node3
   
   # On node1
   pcs cluster setup mycluster node1 node2 node3
   ```

2. **Configure Quorum**
   ```bash
   # Enable quorum
   pcs property set no-quorum-policy=stop
   
   # Configure quorum device (if using)
   pcs quorum device add model net
   ```

3. **Start Cluster**
   ```bash
   pcs cluster start --all
   pcs cluster enable --all
   ```

## Corosync Configuration

### Basic Configuration

1. **Edit Corosync Configuration**
   ```bash
   sudo vi /etc/corosync/corosync.conf
   ```

2. **Example Configuration**
   ```conf
   totem {
     version: 2
     cluster_name: mycluster
     transport: udpu
     interface {
       ringnumber: 0
       bindnetaddr: <local_ip>
       broadcast: yes
       mcastport: 5405
     }
   }

   quorum {
     provider: corosync_votequorum
     two_node: 1
   }

   nodelist {
     node {
       ring0_addr: <node1_ip>
       name: node1
       nodeid: 1
     }
     node {
       ring0_addr: <node2_ip>
       name: node2
       nodeid: 2
     }
   }

   logging {
     to_logfile: yes
     logfile: /var/log/corosync/corosync.log
     to_syslog: yes
     timestamp: on
   }
   ```

### Advanced Configuration

1. **Network Configuration**
   - Configure network interfaces
   - Set up redundancy
   - Configure firewall rules

2. **Security Settings**
   - Configure authentication
   - Set up encryption
   - Manage permissions

3. **Performance Tuning**
   - Adjust timeouts
   - Configure resource limits
   - Optimize network settings

## Cluster Management

### Basic Commands

1. **Check Cluster Status**
   ```bash
   pcs status
   pcs cluster status
   ```

2. **Manage Nodes**
   ```bash
   pcs node standby <node>
   pcs node unstandby <node>
   ```

3. **Resource Management**
   ```bash
   pcs resource show
   pcs resource cleanup <resource>
   ```

### Maintenance Procedures

1. **Adding Nodes**
   ```bash
   pcs cluster node add <new_node>
   ```

2. **Removing Nodes**
   ```bash
   pcs cluster node remove <node>
   ```

3. **Updating Configuration**
   ```bash
   pcs cluster cib-push <file>
   ```

## Troubleshooting

### Common Issues

1. **Node Communication**
   - Check network connectivity
   - Verify firewall rules
   - Check Corosync logs

2. **Resource Failures**
   - Check resource logs
   - Verify configuration
   - Check permissions

3. **Quorum Issues**
   - Verify node status
   - Check quorum configuration
   - Review logs

### Log Files

- `/var/log/corosync/corosync.log`
- `/var/log/pacemaker/pacemaker.log`
- `/var/log/messages`

## Best Practices

1. **Network Configuration**
   - Use dedicated network for cluster communication
   - Configure redundancy
   - Monitor network health

2. **Security**
   - Use strong authentication
   - Enable encryption
   - Regular security updates

3. **Monitoring**
   - Set up monitoring
   - Configure alerts
   - Regular health checks 
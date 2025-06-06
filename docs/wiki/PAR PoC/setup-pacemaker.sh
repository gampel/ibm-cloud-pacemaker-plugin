#!/bin/bash
set +x
pwd
# Source environment files if they exist
if [ -f "fw_install_params.env" ]; then
    source fw_install_params.env
else
    echo "Error: fw_install_params.env not found"
    exit 1
fi

if [ -f "web_install_params.env" ]; then
    source web_install_params.env
    WEB_VIP=$WEB_APP_1_IP  # Using first web app IP as the VIP
else
    echo "Error: web_install_params.env not found"
    exit 1
fi

# Configure /etc/hosts with cluster nodes
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Pacemaker cluster nodes
$FW1_MGMT_IP    pacemaker-node-1
$FW2_MGMT_IP    pacemaker-node-2
$QUORUM_MGMT_IP quorum-device
EOF

# Install required packages
yum update -y
yum install -y  iptables-services git make 
# Download and install resource-agents.src.rpm from GitHub if not already installed
REPO_RAW_BASE="https://raw.githubusercontent.com/gampel/ibm-cloud-pacemaker-plugin/refs/heads/main"
AGENT_RPM_URL="$REPO_RAW_BASE/deps/resource-agents.src.rpm"
INSTALL_YUM_URL="$REPO_RAW_BASE/distributions/install.yum"
 
git clone https://github.com/gampel/ibm-cloud-pacemaker-plugin.git

cd ibm-cloud-pacemaker-plugin

make install
# Enable and start services
systemctl enable --now pcsd
systemctl enable --now corosync
systemctl enable --now pacemaker
systemctl restart corosync

# Set password for hacluster user
echo "hacluster" | passwd --stdin hacluster

# Configure firewall
systemctl enable --now iptables
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Create iptables directory if it doesn't exist
mkdir -p /etc/iptables

sudo iptables -A INPUT  -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow ICMP (ping and other ICMP types)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT


# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow Pacemaker and Corosync ports
# Required on all nodes (pcsd Web UI and node-to-node communication)
iptables -A INPUT -p tcp --dport 2224 -j ACCEPT

# Required on all nodes if the cluster has any Pacemaker Remote nodes
iptables -A INPUT -p tcp --dport 3121 -j ACCEPT

# Required on the quorum device host when using corosync-qnetd
iptables -A INPUT -p tcp --dport 5403 -j ACCEPT

# Required on corosync nodes if corosync is configured for multicast UDP
iptables -A INPUT -p udp --dport 5404 -j ACCEPT

# Required on all corosync nodes
iptables -A INPUT -p udp --dport 5405 -j ACCEPT

# Required on all nodes if the cluster contains any resources requiring DLM
iptables -A INPUT -p tcp --dport 21064 -j ACCEPT

# Required for Booth ticket manager in multi-site clusters
iptables -A INPUT -p tcp --dport 9929 -j ACCEPT
iptables -A INPUT -p udp --dport 9929 -j ACCEPT

# Allow incoming connections from Pacemaker nodes
iptables -A INPUT -s $FW1_MGMT_IP -j ACCEPT
iptables -A INPUT -s $FW2_MGMT_IP -j ACCEPT

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

# Allow web traffic in FORWARD chain
iptables -A FORWARD -i eth0 -p tcp -d $WEB_VIP --dport 80 -j ACCEPT
iptables -A FORWARD -i eth0 -p tcp -d $WEB_VIP --dport 443 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp -d $WEB_VIP --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp -d $WEB_VIP --dport 443 -j ACCEPT

# Allow web traffic in INPUT chain
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Create rc.local if it doesn't exist
if [ ! -f /etc/rc.d/rc.local ]; then
    touch /etc/rc.d/rc.local
    chmod +x /etc/rc.d/rc.local
fi

# Add iptables restore command to rc.local
echo "iptables-restore < /etc/iptables/rules.v4" >> /etc/rc.d/rc.local

# Set PAR VIP as source IP for eth0
ip addr add $PAR_VIP_IP/32 dev eth0
echo "ip addr add $PAR_VIP_IP/32 dev eth0" >> /etc/rc.d/rc.local

# Enable rc.local service
systemctl enable rc-local
systemctl start rc-local

# Configure hostname based on node type
if [[ $(hostname) == *"pacemaker-node-1"* ]]; then
    echo "Configuring as Active Node"
    yum install -y corosync-qdevice
    yum install -y corosync-qnetd
    # Additional active node specific configurations can be added here
elif [[ $(hostname) == *"pacemaker-node-2"* ]]; then
    echo "Configuring as Passive Node"
    yum install -y corosync-qdevice
    yum install -y corosync-qnetd
    # Additional passive node specific configurations can be added here
elif [[ $(hostname) == *"quorum-device"* ]]; then
    echo "Configuring as Quorum Device"
    yum install -y corosync-qdevice
    yum install -y corosync-qnetd
    systemctl enable --now corosync-qnetd
    # Additional quorum device specific configurations can be added here
fi
systemctl restart corosync
systemctl restart pcsd
# Create a health check script
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
# Check if Pacemaker is running
if ! systemctl is-active --quiet pacemaker; then
    echo "Pacemaker is not running"
    exit 1
fi

# Check if Corosync is running
if ! systemctl is-active --quiet corosync; then
    echo "Corosync is not running"
    exit 1
fi

# Check network connectivity
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "No internet connectivity"
    exit 1
fi

exit 0
EOF

# Make health check script executable
chmod +x /usr/local/bin/health-check.sh

# Add health check to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/health-check.sh") | crontab -

echo "Pacemaker setup completed successfully!"

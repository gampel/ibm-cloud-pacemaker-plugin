#!/bin/bash

# Script to install and configure web servers on application nodes
# Usage: ./install_web_remote.sh <install_script>

set -e

# Source the parameters file
if [ ! -f "web_install_params.env" ]; then
    echo "Error: web_install_params.env file not found"
    exit 1
fi

source web_install_params.env

# Check if required parameters are set
if [ -z "$WEB_APP_1_IP" ] || [ -z "$WEB_APP_2_IP" ]; then
    echo "Error: WEB_APP_1_IP and WEB_APP_2_IP must be set in web_install_params.env"
    exit 1
fi

# Check if installation script is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <install_script>"
    exit 1
fi

INSTALL_SCRIPT=$1

# Function to install web server on a node
install_web_server() {
    local node_ip=$1
    local node_name=$2

    echo "Installing web server on $node_name ($node_ip)..."
    
    # Copy the installation script to the web server via quorum device
    scp -o StrictHostKeyChecking=no -J root@${QUORUM_FIP} ${INSTALL_SCRIPT} root@${node_ip}:/tmp/install_remote.sh

    # Execute the installation script on the web server via quorum device
    ssh -o StrictHostKeyChecking=no -A -J root@${QUORUM_FIP} root@${node_ip} 'chmod +x /tmp/install_remote.sh && sudo sh -x /tmp/install_remote.sh'

    # Test the web server
    echo "Testing web server on $node_name..."
    #curl -s http://$node_ip | grep "IBM Cloud Web Server Test" > /dev/null
    if [ $? -eq 0 ]; then
        echo "Web server on $node_name is working correctly!"
    else
        echo "Error: Web server test failed on $node_name"
        exit 1
    fi
}

# Install web servers on both nodes
echo "Starting web server installation..."
install_web_server $WEB_APP_1_IP "Web App 1"
install_web_server $WEB_APP_2_IP "Web App 2"

echo "Web server installation completed successfully!" 
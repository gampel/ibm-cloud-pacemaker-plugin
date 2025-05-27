#!/bin/bash
# Usage: ./install_fw_remote.sh [<quorum_fip> <fw1_ip> <fw2_ip>] <install_script>
# If the first three parameters are omitted, the script will source fw_install_params.env for the values.

set -e

# Try to source the parameter file if it exists
PARAM_FILE="$(dirname "$0")/fw_install_params.env"
if [ -f "$PARAM_FILE" ]; then
  source "$PARAM_FILE"
fi

# Parse arguments
if [ $# -eq 4 ]; then
  QUORUM_FIP="$1"
  FW1_IP="$2"
  FW2_IP="$3"
  INSTALL_SCRIPT="$4"
elif [ $# -eq 1 ]; then
  INSTALL_SCRIPT="$1"
  : "${QUORUM_FIP:?QUORUM_FIP must be set in env file or as argument}"
  : "${FW1_MGMT_IP:?FW1_MGMT_IP must be set in env file or as argument}"
  : "${FW2_MGMT_IP:?FW2_MGMT_IP must be set in env file or as argument}"
  FW1_IP="$FW1_MGMT_IP"
  FW2_IP="$FW2_MGMT_IP"
else
  echo "Usage: $0 [<quorum_fip> <fw1_ip> <fw2_ip>] <install_script>"
  echo "Or:   $0 <install_script> (with fw_install_params.env present)"
  exit 1
fi

# Function to copy and run the install script on a firewall using the quorum FIP as a jump host
run_fw_install() {
  local FW_IP="$1"
  # Copy the environment files using scp with jump host
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=root@${QUORUM_FIP} \
      "$(dirname "$0")/fw_install_params.env" \
      "$(dirname "$0")/web_install_params.env" \
      root@${FW_IP}:~/
  
  # Copy the script using scp with jump host
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=root@${QUORUM_FIP} \
      ${INSTALL_SCRIPT} root@${FW_IP}:/tmp/install_remote.sh
  
  # Run the script using ssh with jump host
  ssh -o StrictHostKeyChecking=no -A -J root@${QUORUM_FIP} root@${FW_IP} 'chmod +x /tmp/install_remote.sh && sudo sh -x /tmp/install_remote.sh'
}

# Run on fw1 and fw2
run_fw_install "$FW1_IP"
run_fw_install "$FW2_IP" 

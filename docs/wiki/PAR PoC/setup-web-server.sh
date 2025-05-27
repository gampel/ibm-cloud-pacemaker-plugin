set -e

echo "Setting up web server..."

# Install required packages
yum update -y
yum install -y httpd jq 
systemctl enable --now httpd


# Get instance metadata
echo "Getting instance metadata..."
export instance_identity_token=`curl -X PUT "http://api.metadata.cloud.ibm.com/instance_identity/v1/token?version=2024-11-12"\
  -H "Metadata-Flavor: ibm"\
  -H "Accept: application/json"\
  -d '{
        "expires_in": 3600
      }' | jq -r '(.access_token)'`

vpc_metadata_api_endpoint=http://api.metadata.cloud.ibm.com
INSTANCE_INFO=$(curl -X GET "$vpc_metadata_api_endpoint/metadata/v1/instance?version=2025-05-13" -H "Authorization: Bearer $instance_identity_token" | jq -r '.')

# Extract instance details
INSTANCE_NAME=$(echo $INSTANCE_INFO | jq -r '.name')
INSTANCE_ID=$(echo $INSTANCE_INFO | jq -r '.id')
INSTANCE_ZONE=$(echo $INSTANCE_INFO | jq -r '.zone.name')
INSTANCE_IP=$(echo $INSTANCE_INFO | jq -r '.network_interfaces[0].primary_ip.address')

# Create a static index.html with instance information
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>IBM Cloud Web Server Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #005073;
        }
        .info {
            margin-top: 20px;
            padding: 10px;
            background-color: #e8f4f8;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class='container'>
        <h1>IBM Cloud Web Server Test Page</h1>
        <div class='info'>
            <p><strong>Instance Name:</strong> ${INSTANCE_NAME}</p>
            <p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>
            <p><strong>Zone:</strong> ${INSTANCE_ZONE}</p>
            <p><strong>IP Address:</strong> ${INSTANCE_IP}</p>
            <p><strong>Time:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
        </div>
    </div>
</body>
</html>
EOF
 

# Configure SELinux and firewall
setsebool -P httpd_can_network_connect 1
 
# Enable IP forwarding
 
# Get the interface IP address
INTERFACE_IP=$(ip route get 1 | awk '{print $7;exit}')

# Configure iptables rules
echo "Configuring iptables rules..."

 

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

 
# Save iptables rules
#service iptables save

# Restart Apache to apply changes
systemctl restart httpd

echo "Web server setup completed successfully!" 
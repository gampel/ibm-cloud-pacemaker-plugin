terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.0"
    }
  }
}

provider "ibm" {
  region = var.region
}

# Variables
variable "prefix" {
  description = "Prefix to be added to all resource names"
  type        = string
  default     = "par-poc"
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
  default     = "au-syd"
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "pacemaker-vpc"
}

variable "zones" {
  description = "List of zones for deployment"
  type        = list(string)
  default     = ["au-syd-1", "au-syd-2", "au-syd-3"]
}

variable "ssh_key" {
  description = "SSH key name"
  type        = string
}

variable "image" {
  description = "OS image for VSI"
  type        = string
  default     = "ibm-centos-stream-9-amd64-10"
}

variable "profile" {
  description = "VSI profile"
  type        = string
  default     = "bx2-2x8"
}

variable "trusted_profile_name" {
  description = "(Optional) Name of the IAM Trusted Profile to attach to VSIs. If not set, no trusted profile will be attached."
  type        = string
  default     = null
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  sensitive   = true
}

variable "par_vip_ip" {
  description = "PAR VIP IP address to be used for the floating IP"
  type        = string
}

# VPC and Network Resources
resource "ibm_is_vpc" "vpc" {
  name           = "${var.prefix}-${var.vpc_name}"
  resource_group = var.resource_group
}

# Create address prefixes for each zone
resource "ibm_is_vpc_address_prefix" "prefixes" {
  count      = length(var.zones)
  name       = "${var.prefix}-prefix-${var.zones[count.index]}"
  vpc        = ibm_is_vpc.vpc.id
  zone       = var.zones[count.index]
  cidr       = "10.240.${count.index}.0/24"
  is_default = false
}

# Create app address prefixes for each zone
resource "ibm_is_vpc_address_prefix" "app_prefixes" {
  count      = 2  # Only need prefixes for AZ1 and AZ2
  name       = "${var.prefix}-app-prefix-${var.zones[count.index]}"
  vpc        = ibm_is_vpc.vpc.id
  zone       = var.zones[count.index]
  cidr       = "10.241.${count.index}.0/24"
  is_default = false
}

# Create Public Gateways for each AZ
resource "ibm_is_public_gateway" "pgw_az1" {
  name           = "${var.prefix}-pgw-az1"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zones[0]
  resource_group = var.resource_group
}

resource "ibm_is_public_gateway" "pgw_az2" {
  name           = "${var.prefix}-pgw-az2"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zones[1]
  resource_group = var.resource_group
}

# Update firewall subnets to attach to Public Gateways
resource "ibm_is_subnet" "firewall_subnets" {
  count           = 2  # Only need 2 subnets for Pacemaker nodes
  name            = "${var.prefix}-firewall-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[count.index]
  ipv4_cidr_block = cidrsubnet(ibm_is_vpc_address_prefix.prefixes[count.index].cidr, 1, 0) # first /25
  resource_group  = var.resource_group
  public_gateway  = count.index == 0 ? ibm_is_public_gateway.pgw_az1.id : ibm_is_public_gateway.pgw_az2.id
}

# Update app subnets to attach to Public Gateways
resource "ibm_is_subnet" "app_subnets" {
  count           = 2  # Only need 2 subnets for application servers
  name            = "${var.prefix}-app-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[count.index]
  ipv4_cidr_block = cidrsubnet(ibm_is_vpc_address_prefix.app_prefixes[count.index].cidr, 1, 0) # first /25
  resource_group  = var.resource_group
  public_gateway  = count.index == 0 ? ibm_is_public_gateway.pgw_az1.id : ibm_is_public_gateway.pgw_az2.id
}

# Quorum subnet (first /25 of the third zone's /24)
resource "ibm_is_subnet" "quorum_subnet" {
  name            = "${var.prefix}-quorum-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[2]
  ipv4_cidr_block = cidrsubnet(ibm_is_vpc_address_prefix.prefixes[2].cidr, 1, 0) # first /25 of third zone
  resource_group  = var.resource_group
}

# Create security groups
resource "ibm_is_security_group" "firewall_sg" {
  name           = "${var.prefix}-firewall-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group
}

resource "ibm_is_security_group" "app_sg" {
  name           = "${var.prefix}-app-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group
}

# Security group rules for firewall
resource "ibm_is_security_group_rule" "firewall_inbound" {
  group     = ibm_is_security_group.firewall_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# Allow all traffic between firewall nodes (same security group)
resource "ibm_is_security_group_rule" "firewall_internal" {
  group     = ibm_is_security_group.firewall_sg.id
  direction = "inbound"
  remote    = ibm_is_security_group.firewall_sg.id
}

resource "ibm_is_security_group_rule" "firewall_outbound" {
  group     = ibm_is_security_group.firewall_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Security group rules for application
resource "ibm_is_security_group_rule" "app_inbound" {
  group     = ibm_is_security_group.app_sg.id
  direction = "inbound"
  remote    = ibm_is_security_group.firewall_sg.id
  tcp {
    port_min = 80
    port_max = 80
  }
}

# Management address prefixes
resource "ibm_is_vpc_address_prefix" "mgmt_prefixes" {
  count      = length(var.zones)
  name       = "${var.prefix}-mgmt-prefix-${var.zones[count.index]}"
  vpc        = ibm_is_vpc.vpc.id
  zone       = var.zones[count.index]
  cidr       = "10.250.${count.index}.0/24"
  is_default = false
}

# Management subnets
resource "ibm_is_subnet" "mgmt_subnets" {
  count           = length(var.zones)
  name            = "${var.prefix}-mgmt-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[count.index]
  ipv4_cidr_block = ibm_is_vpc_address_prefix.mgmt_prefixes[count.index].cidr
  resource_group  = var.resource_group
}

# Pacemaker node 1 VNIs
resource "ibm_is_virtual_network_interface" "pacemaker1_mgmt" {
  name           = "${var.prefix}-pacemaker1-mgmt-vni"
  subnet         = ibm_is_subnet.mgmt_subnets[0].id
  resource_group = var.resource_group
  security_groups = [ibm_is_security_group.firewall_sg.id]
}

# Pacemaker node 1 data interface
resource "ibm_is_instance_network_interface" "pacemaker1_mgmt" {
  name              = "${var.prefix}-pacemaker1-mgmt-nic"
  instance          = ibm_is_instance.pacemaker_node_1.id
  subnet            = ibm_is_subnet.firewall_subnets[0].id
  allow_ip_spoofing = true
  security_groups   = [ibm_is_security_group.firewall_sg.id]
}

resource "ibm_is_instance" "pacemaker_node_1" {
  name            = "${var.prefix}-pacemaker-node-1"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[0]
  profile         = var.profile
  image           = var.image
  keys            = [var.ssh_key]
  resource_group  = var.resource_group
  metadata_service {
    enabled = true
  }
  primary_network_interface {
    subnet            = ibm_is_subnet.mgmt_subnets[0].id
    security_groups   = [ibm_is_security_group.firewall_sg.id]
    # Uncomment below to use a trusted profile
    # profile {
    #   name = var.trusted_profile_name
    # }
  }
}

# Pacemaker node 2 VNIs
resource "ibm_is_virtual_network_interface" "pacemaker2_mgmt" {
  name           = "${var.prefix}-pacemaker2-mgmt-vni"
  subnet         = ibm_is_subnet.mgmt_subnets[1].id
  resource_group = var.resource_group
  security_groups = [ibm_is_security_group.firewall_sg.id]
}

# Pacemaker node 2 data interface
resource "ibm_is_instance_network_interface" "pacemaker2_mgmt" {
  name              = "${var.prefix}-pacemaker2-mgmt-nic"
  instance          = ibm_is_instance.pacemaker_node_2.id
  subnet            = ibm_is_subnet.firewall_subnets[1].id
  allow_ip_spoofing = true
  security_groups   = [ibm_is_security_group.firewall_sg.id]
}

resource "ibm_is_instance" "pacemaker_node_2" {
  name            = "${var.prefix}-pacemaker-node-2"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[1]
  profile         = var.profile
  image           = var.image
  keys            = [var.ssh_key]
  resource_group  = var.resource_group
  metadata_service {
    enabled = true
  }
  primary_network_interface {
    subnet            = ibm_is_subnet.mgmt_subnets[1].id
    security_groups   = [ibm_is_security_group.firewall_sg.id]
    # Uncomment below to use a trusted profile
    # profile {
    #   name = var.trusted_profile_name
    # }
  }
}

# Quorum device VNIs
resource "ibm_is_virtual_network_interface" "quorum_mgmt" {
  name           = "${var.prefix}-quorum-mgmt-vni"
  subnet         = ibm_is_subnet.mgmt_subnets[2].id
  resource_group = var.resource_group
  security_groups = [ibm_is_security_group.firewall_sg.id]
}

# Quorum device data interface
resource "ibm_is_instance_network_interface" "quorum_mgmt" {
  name              = "${var.prefix}-quorum-mgmt-nic"
  instance          = ibm_is_instance.quorum_device.id
  subnet            = ibm_is_subnet.quorum_subnet.id
  allow_ip_spoofing = true
  security_groups   = [ibm_is_security_group.firewall_sg.id]
}

resource "ibm_is_instance" "quorum_device" {
  name            = "${var.prefix}-quorum-device"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[2]
  profile         = var.profile
  image           = var.image
  keys            = [var.ssh_key]
  resource_group  = var.resource_group
  metadata_service {
    enabled = true
  }
  primary_network_interface {
    subnet            = ibm_is_subnet.mgmt_subnets[2].id
    security_groups   = [ibm_is_security_group.firewall_sg.id]
    # Uncomment below to use a trusted profile
    # profile {
    #   name = var.trusted_profile_name
    # }
  }
}

# Attach a Floating IP to the Quorum device's management interface
resource "ibm_is_floating_ip" "quorum_mgmt_fip" {
  name           = "${var.prefix}-quorum-mgmt-fip"
  target         = ibm_is_instance.quorum_device.primary_network_interface[0].id
  resource_group = var.resource_group
}

# Web application 1 VNI
resource "ibm_is_virtual_network_interface" "web_app_1_vni" {
  name           = "${var.prefix}-web-app-1-vni"
  subnet         = ibm_is_subnet.app_subnets[0].id
  resource_group = var.resource_group
  security_groups = [ibm_is_security_group.app_sg.id]
}

resource "ibm_is_instance" "web_app_1" {
  name            = "${var.prefix}-web-app-1"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[0]
  profile         = var.profile
  image           = var.image
  keys            = [var.ssh_key]
  resource_group  = var.resource_group
  metadata_service {
    enabled = true
  }
  primary_network_interface {
    subnet            = ibm_is_subnet.app_subnets[0].id
    security_groups   = [ibm_is_security_group.app_sg.id]
    # Uncomment below to use a trusted profile
    # profile {
    #   name = var.trusted_profile_name
    # }
  }
}

# Web application 2 VNI
resource "ibm_is_virtual_network_interface" "web_app_2_vni" {
  name           = "${var.prefix}-web-app-2-vni"
  subnet         = ibm_is_subnet.app_subnets[1].id
  resource_group = var.resource_group
  security_groups = [ibm_is_security_group.app_sg.id]
}

resource "ibm_is_instance" "web_app_2" {
  name            = "${var.prefix}-web-app-2"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zones[1]
  profile         = var.profile
  image           = var.image
  keys            = [var.ssh_key]
  resource_group  = var.resource_group
  metadata_service {
    enabled = true
  }
  primary_network_interface {
    subnet            = ibm_is_subnet.app_subnets[1].id
    security_groups   = [ibm_is_security_group.app_sg.id]
    # Uncomment below to use a trusted profile
    # profile {
    #   name = var.trusted_profile_name
    # }
  }
}

# Create a new routing table for ingress with public internet ingress enabled
resource "ibm_is_vpc_routing_table" "ingress" {
  name           = "${var.prefix}-ingress-table"
  vpc            = ibm_is_vpc.vpc.id
  route_internet_ingress = true
}

data "ibm_resource_group" "rg" {
  name = "Default"
}

# Add a shell wrapper script for create_par.py
# File: docs/wiki/PAR PoC/run_create_par.sh
# Usage: ./run_create_par.sh <VPC_ID> <RG_ID> <NAME> <ZONE>

#resource "null_resource" "create_par" {
#  provisioner "local-exec" {
#    command = "bash run_create_par.sh ${ibm_is_vpc.vpc.id} ${data.ibm_resource_group.rg.id} pacemaker-par ${var.zones[0]}"
#    environment = {
#      IC_API_KEY = var.ibmcloud_api_key
#    }
#  }
#}

#data "external" "par_prefix" {
#  depends_on = [null_resource.create_par]
#  program = ["bash", "docs/wiki/PAR PoC/run_create_par.sh", ibm_is_vpc.vpc.id, data.ibm_resource_group.rg.id, "pacemaker-par", var.zones[0]]
##  
#}

resource "ibm_is_vpc_routing_table_route" "ingress_par_to_fw" {
  vpc            = ibm_is_vpc.vpc.id
  routing_table  = ibm_is_vpc_routing_table.ingress.routing_table
  destination    = "0.0.0.0/0"
  next_hop       = ibm_is_instance.pacemaker_node_1.primary_network_interface[0].primary_ip[0].address
  action         = "deliver"
  name           = "ingress-par-to-fw"
  zone           = var.zones[0]
}

# Outputs
output "par_prefix" {
  value = ibm_is_vpc_address_prefix.prefixes[0].cidr
}

output "pacemaker_node_ips" {
  value = {
    "pacemaker-node-1" = ibm_is_instance.pacemaker_node_1.primary_network_interface[0].primary_ip[0].address
    "pacemaker-node-2" = ibm_is_instance.pacemaker_node_2.primary_network_interface[0].primary_ip[0].address
  }
}

output "quorum_device_ip" {
  value = ibm_is_instance.quorum_device.primary_network_interface[0].primary_ip[0].address
}

output "web_app_private_ips" {
  value = [
    ibm_is_instance.web_app_1.primary_network_interface[0].primary_ip[0].address,
    ibm_is_instance.web_app_2.primary_network_interface[0].primary_ip[0].address
  ]
}

output "quorum_fip" {
  value = ibm_is_floating_ip.quorum_mgmt_fip.address
}

output "fw1_mgmt_ip" {
  value = ibm_is_instance.pacemaker_node_1.primary_network_interface[0].primary_ip[0].address
}

output "fw2_mgmt_ip" {
  value = ibm_is_instance.pacemaker_node_2.primary_network_interface[0].primary_ip[0].address
}

output "quorum_fip_ip" {
  value = ibm_is_floating_ip.quorum_mgmt_fip.address
}

# Generate firewall installation parameters
resource "local_file" "fw_install_params" {
  content = <<EOT
QUORUM_FIP="${ibm_is_floating_ip.quorum_mgmt_fip.address}"
FW1_MGMT_IP="${ibm_is_instance.pacemaker_node_1.primary_network_interface[0].primary_ip[0].address}"
FW2_MGMT_IP="${ibm_is_instance.pacemaker_node_2.primary_network_interface[0].primary_ip[0].address}"
QUORUM_MGMT_IP="${ibm_is_instance.quorum_device.primary_network_interface[0].primary_ip[0].address}"
PAR_VIP_IP="${var.par_vip_ip}"
EOT
  filename = "${path.module}/fw_install_params.env"
}

# Generate web server installation parameters
resource "local_file" "web_install_params" {
  content = <<EOT
WEB_APP_1_IP="${ibm_is_instance.web_app_1.primary_network_interface[0].primary_ip[0].address}"
WEB_APP_2_IP="${ibm_is_instance.web_app_2.primary_network_interface[0].primary_ip[0].address}"
QUORUM_FIP="${ibm_is_floating_ip.quorum_mgmt_fip.address}"
QUORUM_MGMT_IP="${ibm_is_instance.quorum_device.primary_network_interface[0].primary_ip[0].address}"
PAR_VIP_IP="${var.par_vip_ip}"
EOT
  filename = "${path.module}/web_install_params.env"
} 
# IBM Cloud region (e.g., "au-syd", "us-south", "eu-gb")
region         = ""

# Resource group ID where resources will be created
resource_group = ""

# Name of the VPC to be created
vpc_name       = ""

# List of availability zones for the region
zones          = []

# SSH key ID to be used for VSI access
ssh_key        = ""

# Custom image ID to be used for VSIs
image          = ""

# VSI profile/instance type (e.g., "bx2-2x8", "bx2-4x16")
profile        = ""

# CIDR block for the VPC subnet
ipv4_cidr_block = ""

# Flag to control whether VSIs should be stopped after apply
stop_vsis_after_apply = false

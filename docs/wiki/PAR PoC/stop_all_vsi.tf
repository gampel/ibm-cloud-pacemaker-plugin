# Variable to control VSI stopping behavior
variable "stop_vsis_after_apply" {
  description = "Whether to stop all VSIs after applying the configuration"
  type        = bool
  default     = false
}

resource "null_resource" "stop_all_vsi" {
  count = var.stop_vsis_after_apply ? 1 : 0  # Only create this resource if stop_vsis_after_apply is true
  
  provisioner "local-exec" {
    command = <<EOT
ibmcloud login --apikey $IBMCLOUD_API_KEY -r ${var.region} -g ${var.resource_group}
ibmcloud is instance-stop ${ibm_is_instance.pacemaker_node_1.id} --force
ibmcloud is instance-stop ${ibm_is_instance.pacemaker_node_2.id} --force
ibmcloud is instance-stop ${ibm_is_instance.quorum_device.id} --force
ibmcloud is instance-stop ${ibm_is_instance.web_app_1.id} --force
ibmcloud is instance-stop ${ibm_is_instance.web_app_2.id} --force
EOT
    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
    }
    interpreter = ["/bin/bash", "-c"]
  }
}

  
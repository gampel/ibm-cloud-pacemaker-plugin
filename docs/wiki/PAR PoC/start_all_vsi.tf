resource "null_resource" "start_all_vsi" {
  provisioner "local-exec" {
    command = <<EOT
ibmcloud login --apikey $IBMCLOUD_API_KEY -r ${var.region} -g ${var.resource_group}
ibmcloud is instance-start ${ibm_is_instance.pacemaker_node_1.id}
ibmcloud is instance-start ${ibm_is_instance.pacemaker_node_2.id}
ibmcloud is instance-start ${ibm_is_instance.quorum_device.id}
ibmcloud is instance-start ${ibm_is_instance.web_app_1.id}
ibmcloud is instance-start ${ibm_is_instance.web_app_2.id}
EOT
    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
    }
    interpreter = ["/bin/bash", "-c"]
  }
}





```markdown
# IBM Cloud VPC Pacemaker Plugin

This repository contains the IBM Cloud Pacemaker Plugin, which provides integration between IBM Cloud and the Pacemaker cluster resource manager. The plugin enables you to manage cloud resources and deployment within Pacemaker, allowing high availability for your applications in the IBM VPC Cloud environment.

## Background

Pacemaker is an open-source high-availability (HA) cluster resource manager widely used for managing cluster resources. The IBM Cloud Pacemaker Plugin extends Pacemaker’s capabilities by adding support for managing IBM Cloud resources in Active Passive mode, providing an easy way to deploy cloud-based applications in a high-availability setup.

## Features

- Seamless integration with IBM Cloud.
- Ability to manage cloud resources directly from Pacemaker.
- High availability for applications running on IBM Cloud.
- For 
	- Custom route VIP,  active passive same AZ or Cross AZ  
	- Floating IP Failover (same AZ)
- Supports easy configuration and deployment.

## Prerequisites

- A working IBM Cloud account.
- VNI-based Virtual Network Interfaces 
- [Instance Metadata enabled](https://cloud.ibm.com/docs/vpc?topic=vpc-imd-about) on the VSI pairs 
- Access to a machine capable of running a Pacemaker.
- [IBM Cloud VPC Python SDK](https://github.com/IBM/vpc-python-sdk) 
- Installation of Pacemaker on the cluster.
- 

## Installation

1. **Clone the Repository**:
   First, clone the GitHub repository to your local machine:

   ```bash
   git clone https://github.com/gampel/ibm-cloud-pacemaker-plugin.git
   ```

2. **Build the Plugin**:
   Navigate into the cloned directory and build the plugin:

   ```bash
   cd ibm-cloud-pacemaker-plugin
   make
   ```

3. **Install the Plugin**:
   Depending on your setup, you may need to copy the plugin files to the appropriate directories used by Pacemaker:

   ```bash
   sudo cp <plugin-binary> /usr/lib/pacemaker/
   ```

   Replace `<plugin-binary>` with the actual binary name created during the build process.

4. **Configure the Plugin**:
   Configure the plugin to connect with your IBM Cloud account. You may have to define the necessary credentials and configurations in the Pacemaker configuration files.

## Usage

1. **Start the Pacemaker Service**:
   Ensure that your Pacemaker service is running. You can start it with:

   ```bash
   sudo systemctl start pacemaker
   ```

2. **Add Resources**:
   Use the Pacemaker command-line interface to add IBM Cloud resources. For example:

   ```bash
   
   pcs resource create  customRouteFailover ocf:ibm-cloud:customRouteFailover   \
                        api_key="API_KEY" \
                        ext_ip_1="IP_1"   \
                        ext_ip_2="IP_2"   \
                        vpc_url="https://eu-es.iaas.cloud.ibm.com/v1"
   ```
   

 

api_key = `[IBM Cloud API Key](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui) Your VPC Access API key` 
 
ext_ip_1 = `Private IP for the first VSI`enter code here
 
ext_ip_2 =  `Private IP for the second VSI`
 
vpc_url  =  `The VPC URL to be used can be the Public VPC API endpoint for your region or VPE (private path) to your regional VPC API endpoint.
    `
```bash   
pcs resource create  floatingIpFailover  ocf:ibm-cloud:floatingIpFailover  \
                       api_key="API_KEY" \
                       vni_id_1="02w7-afc89131-7901-4603-848a-5488680c683d" \
                       vni_id_2="02w7-c0f2ff9b-3128-4d91-ab32-7d612659867d" \
                       fip_id="r050-f0e45301-f07d-4117-86b7-dd0ea60e5b9f" \
                       vpc_url="https://eu-es.iaas.cloud.ibm.com/v1"
   ```
  api_key =  `IBM Cloud API Key Your VPC Access API key`  
 
vni_id_1 = `First Virtual Network Interface (VNI) uuid`

vni_id_2 = `Secound Virtual Network Interface (VNI) uuid`

fip_id =  `Floating IP uuid we want to use`
 
vpc_url  =  `The VPC URL to be used can be the Public VPC API endpoint for your region or VPE (private path) to your regional VPC API endpoint.
   Replace `MyResource` and `[property=value]` with your resource name and properties accordingly.

3. **Monitor and Manage Resources**:
   You can monitor and manage your resources using standard Pacemaker commands:

   ```bash
   crm status
   crm resource show
   ```

4. **Failover and Recovery**:
   Pacemaker will automatically manage failover based on your configuration, ensuring high availability of your resources.

## Contribution

Contributions to the project are welcome. If you would like to contribute, please fork the repository and open a pull request with a clear description of your changes and their benefits.

## License

This project is licensed under the   . See the LICENSE file for more details.

## Contact

For issues, feature requests, or other inquiries about the IBM Cloud Pacemaker Plugin, please open an issue in this repository or reach out directly to the maintainers.
```

### Next Steps:
To send this as a pull request (PR) to the repository:

1. Fork the repository.
2. Update the README.md in your fork with the above content.
3. Commit your changes and push them to your fork.
4. Navigate to the original repository (https://github.com/gampel/ibm-cloud-pacemaker-plugin).
5. Click on the "Pull requests" tab and then "New pull request."
6. Select your fork and compare it with the base repository, then create the pull request.

Feel free to adjust any sections according to your preferences or additional information you may want to include!

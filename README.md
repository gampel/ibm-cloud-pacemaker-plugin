

```markdown
# IBM Cloud VPC Pacemaker Plugin

This repository contains the IBM Cloud Pacemaker Plugins, which provides integration between IBM Cloud and the Pacemaker
cluster resource manager. The plugin enables you to manage cloud resources and deployment within Pacemaker, allowing high
availability for your applications in the IBM VPC Cloud environment.

## Background

Pacemaker is an open-source high-availability (HA) cluster resource manager widely used for managing cluster resources.
The IBM Cloud Pacemaker Plugin extends Pacemaker’s capabilities by adding support for managing IBM Cloud resources in
Active Passive mode, providing an easy way to deploy cloud-based applications in a high-availability setup.

## Features

- Seamless integration with IBM Cloud.
- Ability to manage cloud resources directly from Pacemaker.
- High availability for applications running on IBM Cloud.
- For 
	- Custom route VIP,  active passive same AZ or Cross/Multi-AZ  
	- Floating IP Failover (Singel AZ)
- Supports easy configuration and deployment.

## Prerequisites

- A working IBM Cloud account.
- VNI-based Virtual Network Interfaces pair to be used as active-passive pair
- allow_ip_spoofing enabled on the Virtual network interface  
- [Instance Metadata enabled](https://cloud.ibm.com/docs/vpc?topic=vpc-imd-about) on the VSI pairs 
- Access to a machine capable of running a Pacemaker.
- [IBM Cloud VPC Python SDK](https://github.com/IBM/vpc-python-sdk) 
- Installation of Pacemaker on the Active Passive cluster

## Installation

1. **Clone the Repository**:
   First, clone the GitHub repository to your local machine:

   ```bash
   git clone https://github.com/gampel/ibm-cloud-pacemaker-plugin.git
   ```
    
2. **Install the Plugin & dependencies **:
   Navigate into the cloned directory and build the plugin:

   ```bash
   cd ibm-cloud-pacemaker-plugin
   make install_all 
   ```
   Currently, only apt-get (Ubuntu) based install is supported

4. **Configure CoroSync**:
   Configure /etc/corosync/corosync.conf with your two nodes Active Passive Ips 

   

Example Configuration is provided in [corosync.conf](https://github.com/gampel/ibm-cloud-pacemaker-plugin/blob/main/conf/corosync.conf)
  

        totem {
      version: 2
      cluster_name: IBM-cluster
      transport: udpu
      interface {
        ringnumber: 0
        bindnetaddr: <Loacl_Ip>
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
        ring0_addr: <vsi_1_ip>
        name: primary
        nodeid: 1
      }
      node {
        ring0_addr: <vs_2_ip>
        name: secondary
        nodeid: 2
      }
    }
    
    logging {
      to_logfile: yes
      logfile: /var/log/corosync/corosync.log
      to_syslog: yes
      timestamp: on
    }

Do the same setup on both Selected VSI pair 

Copy the created auth key as part of the install to be the selected pair auth key

    scp /etc/corosync/authkey username@second_vsi_ip:/tmp
    
Copy it in  the second VSI to the /etc/corosync/authkey  directory and make sure it is root-owned 

    sudo mv /tmp/authkey /etc/corosync
    sudo chown root: /etc/corosync/authkey
    sudo chmod 400 /etc/corosync/authkey  

Now we nee to restart corosyn of both VSIs 

    sudo service corosync restart 

Set stonith to false on both VSI's

    pcs property set stonith-enabled=false

Run pcs status you should get the following: 

    :>> pcs status
    Cluster name: IBM-HA-Cluster
    Cluster Summary:
      * Stack: corosync
      * Current DC: primary (version 2.1.2-ada5c3b36e2) - partition with quorum
      * Last updated: Tue Nov 26 18:44:35 2024
      * Last change:  Tue Nov 26 18:44:30 2024 by root via cibadmin on secondary
      * 2 nodes configured
      * 0 resource instances configured
    
    Node List:
      * Online: [ primary secondary ]
    
    Full List of Resources:
      * No resources
    
    Daemon Status:
      corosync: active/enabled
      pacemaker: active/enabled
      pcsd: active/enabled

## Configuring the Pacemaker resource 

1. **Add Resources**:
   Use the Pacemaker command-line interface to add IBM Cloud resources. 
Currently supported resources are:

> customRouteFailover: HA based on IBM Cloud Custom route Supports both same zone and cross-zone HA 

>  floatingIpFailover: Public Ingress HA based on IBM VPC Floating IP 

For example:

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

> For example, for the Madrid Region, we can use
> 
> Private -https://eu-es.private.iaas.cloud.ibm.com/v1
> 
> or
> 
> Public  - https://eu-es.iaas.cloud.ibm.com/v1

   
   Replace `MyResource` and `[property=value]` with your selected resource name and properties accordingly.

Run pcs status you should get the following: 

    Cluster name: IBM-HA-Cluster
    Cluster Summary:
      * Stack: corosync
      * Current DC: primary (version 2.1.2-ada5c3b36e2) - partition with quorum
      * Last updated: Wed Nov 27 16:23:41 2024
      * Last change:  Wed Nov 27 09:43:10 2024 by root via cibadmin on secondary
      * 2 nodes configured
      * 1 resource instance configured
    
    Node List:
      * Online: [ primary secondary ]
    
    Full List of Resources:
      * customRouteFailover	(ocf:ibm-cloud:customRouteFailover):	 Started primary
    
    Daemon Status:
      corosync: active/enabled
      pacemaker: active/enabled
      pcsd: active/enabled

The customRouteFailover  Plugin will seamlessly figure out if the VNI pair are on the same zone  or apply cross az failover in case they are in different zones 

3. **Monitor and Manage Resources**:
   You can monitor and manage your resources using standard Pacemaker commands: 
>
    pcs status
>  
    pcs resource show
>  
    crm mon 

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



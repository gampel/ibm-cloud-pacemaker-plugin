
# IBM Cloud VPC Pacemaker Plugin

This repository contains the IBM Cloud Pacemaker Plugins install, usability guide, and early access 
for the IBM VPC plugins supported in the [ClusterLab](https://github.com/ClusterLabs) repository, which provides
integration between IBM Cloud and the Pacemaker cluster resource manager.
The plugin enables you to manage cloud resources and deployment within
Pacemaker, allowing high availability for your applications in the
IBM VPC Cloud environment.

## Background

Pacemaker is an open-source high-availability (HA) cluster resource manager
widely used for managing cluster resources. The IBM Cloud Pacemaker Plugin
extends Pacemaker’s capabilities by adding support for managing IBM Cloud
resources in Active Passive mode, providing an easy way to deploy cloud-based
applications in a high-availability setup.

## Features

- Seamless integration with IBM Cloud.
- Ability to manage cloud resources directly from Pacemaker.
- High availability for applications running on IBM Cloud.
- For 
	- Custom route VIP,  active passive same AZ or Cross/Multi-AZ  
	- Floating IP Failover (Singel AZ)
- Supports easy configuration and deployment.
- Support Trusted profile IAM token or API key-based 

## Prerequisites

- A working IBM Cloud account.
- VNI-based Virtual Network Interfaces pair to be used as active-passive pair
- allow_ip_spoofing enabled on the Virtual network interface  
- [Instance Metadata enabled](https://cloud.ibm.com/docs/vpc?topic=vpc-imd-about) on the VSI pairs 
- Access to a machine capable of running a Pacemaker.
- [IBM Cloud VPC Python SDK](https://github.com/IBM/vpc-python-sdk) 
- Installation of Pacemaker on the Active Passive cluster

## Installation

Create two VSI's, in the case of the FIP plugin they need to be in the same Zone, in the case of the Custom Route it can be in separated zones.

Please perform steps 1 and 2 on the two VSI's.

1. **Clone the Repository**:
   First, clone the GitHub repository to your local machine:

   ```bash
   git clone https://github.com/gampel/ibm-cloud-pacemaker-plugin.git
   ```
    
2. **Install the Plugin & dependencies**:
   Navigate into the cloned directory and build the plugin:
Install make 
on Ubuntu using 

   ```bash
    sudo apt-get install make
    ```
    or using yum 
    ```bash
    sudo yum install make
    ```

```
  
   cd ibm-cloud-pacemaker-plugin
   make install 
   ```

Make install will install all needed dependencies and compile and install the [resource-agent](https://github.com/ClusterLabs/resource-agents) repository until the next release, which will include the new IBM cloud VPC resources.

4. **Configure CoroSync**:
   
   This example below is a two node setup, which is not intended for production environments, for production environments it is best to use 3 node setup with a separate quorum device (example comming soon).
   
   In the the two-node quorum, Because no tie-breaker mechanism exists, the two-node quorum is prone to the split-brain scenario. It is not intended for production environments.
   I will incldue soon a setup example for 3 node quorum using quorum device.
   
   You can allow a cluster to sustain more node failures than standard quorum rules allows by configuring a separate quorum device which acts as a third-party arbitration device for the cluster. A quorum device is recommended for clusters with an even number of nodes. With two-node clusters, the use of a quorum device can better determine which node survives in a split-brain situation.
   
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
        name: first
        nodeid: 1
      }
      node {
        ring0_addr: <vs_2_ip>
        name: second
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
    pcs property set  no-quorum-policy=ignore 

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
   
   pcs resource create  ibm-cloud-vpc-cr-vip  ocf:heartbeat:ibm-cloud-vpc-cr-vip   \
                        api_key="API_KEY" \
                        ext_ip_1="IP_1"   \
                        ext_ip_2="IP_2"   \
                        vpc_url="https://eu-es.iaas.cloud.ibm.com/v1" \
                        meta resource-stickiness=100 stonith-enabled=false  \
                         no-quorum-policy=ignore 
   ```
   

When Trusted profile IAM token is used the optional api_key parameter is not needed 

api_key = `[IBM Cloud API Key](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui) Your VPC Access API key` 
 
ext_ip_1 = `Private IP for the first VSI`enter code here
 
ext_ip_2 =  `Private IP for the second VSI`
 
vpc_url  =  `The VPC URL to be used can be the Public VPC API endpoint for your region or VPE (private path) to your regional VPC API endpoint.
    `
   
    Adjust resource stickiness depending on your  preference for auto failback, using the above value, the resource prefers to stay where it is after failover 
    
```bash   
pcs resource create  floatingIpFailover   ocf:heartbeat:ibm-cloud-vpc-move-fip  \
                       api_key="API_KEY" \
                       vni_id_1="02w7-afc89131-7901-4603-848a-5488680c683d" \
                       vni_id_2="02w7-c0f2ff9b-3128-4d91-ab32-7d612659867d" \
                       fip_id="r050-f0e45301-f07d-4117-86b7-dd0ea60e5b9f" \
                       vpc_url="https://eu-es.iaas.cloud.ibm.com/v1" \
                       meta resource-stickiness=100 stonith-enabled=false  \
                         no-quorum-policy=ignore 
   ```

  In case you want to use a Trusted profile IAM token do not include api_key parameter
  
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

5. **Setup How to Test**:

Configure two VSIs in the IBM Cloud, and make sure you have instance metadata enabled for both.
Do the setup above.
To test the FIP plugin please attache FIP to one of the VISs and start testing the failover 
To test Custom route VIP, please configure IBM Cloud Egress and Ingress custom route for the prefixes you want to redirect to the HA cluster and set one of the VSI ip as the next on ALL the routes.
The two plugins can work together, but you must make sure that FIP and Custom route nexthop are pointing to the same VSI on startup 
For Example 

    root@eran-new-test2:~# pcs status
    Cluster name: IBM-cluster
    Cluster Summary:
      * Stack: corosync
      * Current DC: secondary (version 2.1.2-ada5c3b36e2) - partition with quorum
      * Last updated: Mon Dec  2 18:29:57 2024
      * Last change:  Mon Dec  2 18:19:11 2024 by root via cibadmin on primary
      * 2 nodes configured
      * 2 resource instances configured
    
    Node List:
      * Online: [ primary secondary ]
    
    Full List of Resources:
      * floatingIpFailover	(ocf:ibm-cloud:floatingIpFailover):	 Started secondary
      * customRouteFailover	(ocf:ibm-cloud:customRouteFailover):	 Started secondary
    
    Daemon Status:
      corosync: active/enabled
      pacemaker: active/enabled
      pcsd: active/enabled
6. **TODO**:

 - Support Secondary ips failover 
 - Support Public Adress Prefix
 - Support encrypted  IBM instance metadata access  

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



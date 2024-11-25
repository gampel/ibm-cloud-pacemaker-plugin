pcs resource create  customRouteFailover ocf:ibm-cloud:customRouteFailover api_key="API_KEY" ext_ip_1="IP_1" ext_ip_2="IP_@" vpc_url="https://eu-es.iaas.cloud.ibm.com/v1"




pcs resource create  floatingIpFailover  ocf:ibm-cloud:floatingIpFailover  api_key="API_KEY" vni_id_1="02w7-afc89131-7901-4603-848a-5488680c683d" vni_id_2="02w7-c0f2ff9b-3128-4d91-ab32-7d612659867d" fip_id="r050-f0e45301-f07d-4117-86b7-dd0ea60e5b9f" fip_id="r050-f0e45301-f07d-4117-86b7-dd0ea60e5b9f" vpc_url="https://eu-es.iaas.cloud.ibm.com/v1"

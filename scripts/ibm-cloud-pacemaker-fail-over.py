#
# Copyright 2024 Eran Gampel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from os import environ as env
from dotenv import load_dotenv
import http.client
import json


load_dotenv('env')

class HAFailOver(object):
   # Parameter to be passed while creating a Code Engine Instance.
    API_KEY = "API_KEY"
    VPC_ID = "VPC_ID"
    VPC_URL = "VPC_URL"
    ZONE = "ZONE"
    VSI_LOCAL_AZ = "VSI_LOCAL_AZ"
    EXT_IP_1 = "EXT_IP_1"
    EXT_IP_2 = "EXT_IP_2"
    EXT_IP_1_ZONE = ""
    EXT_IP_2_ZONE = ""
    apikey = None
    vpc_url = ""
    vpc_id =''
    table_id = ''
    route_id = ''
    zone = ''
    next_hop_vsi = ""
    update_next_hop_vsi = ""
    mgmt_ip_1 = ''
    mgmt_ip_2 = ''
    ext_ip_1 = ''
    ext_ip_2 = ''
    DEBUG = False 
    service = None
    
    def __init__(self):
        self.logger("--------Constructor---------")
        if self.apikey is None:
            self.logger("--------parse_config")
            self.parse_config()
        #authenticator = IAMAuthenticator(self.apikey, url='https://iam.cloud.ibm.com')
        #self.service = VpcV1(authenticator=authenticator)
        #self.service.set_service_url(self.vpc_url)
        #access_token = self.get_token()
        #self.logger("Initialized VPC service!!" + access_token)
    

    def get_token(self):
        # URL for token
        conn = http.client.HTTPSConnection("iam.cloud.ibm.com")
        # Payload for retrieving token. Note: An API key will need to be generated and replaced here
        payload = 'grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=' + self.apikey + '&response_type=cloud_iam'

        # Required headers
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache'
        }

        try:
            # Connect to endpoint for retrieving a token
            conn.request("POST", "/identity/token", payload, headers)

            # Get and read response data
            res = conn.getresponse().read()
            data = res.decode("utf-8")

            # Format response in JSON
            json_res = json.loads(data)

            # Concatenate token type and token value
            return (json_res['token_type'] + ' ' + json_res['access_token'])
        
        # If an error happens while retrieving token
        except Exception as error:
            self.logger(f"Error getting token. {error}")
            raise

    def parameterException(missingParameter):
        raise Exception("Please!!! provide " + missingParameter)
         
    def parse_config(self):
        try:
            self.logger (env)
            if self.API_KEY in env:
                self.apikey = env[self.API_KEY]
                self.logger(self.API_KEY + ": " + self.apikey)
            else:
                self.parameterException(self.API_KEY)
            
            if self.VPC_ID in env:
                self.vpc_id = env[self.VPC_ID]
                self.logger(self.VPC_ID + ": " + self.vpc_id)
            else:
                self.parameterException(self.VPC_ID)
            
            if self.VPC_URL in env:
                self.vpc_url = env[self.VPC_URL]
                self.logger(self.VPC_URL + ": " + self.vpc_url)
            else:
                self.parameterException(self.VPC_URL)

            #if self.ZONE in env:
            #    self.zone = env[self.ZONE]
            #    self.logger(self.ZONE + ": " + self.zone)
            #else:
            #    self.parameterException(self.ZONE)
            if self.VSI_LOCAL_AZ in env:
                self.vsi_local_az = env[self.VSI_LOCAL_AZ]
                self.logger("VSI Local AZ: " + self.vsi_local_az)
            else:
                self.parameterException(self.VSI_LOCAL_AZ)

          

            if self.EXT_IP_1 in env:
                self.ext_ip_1 = env[self.EXT_IP_1]
                self.logger("External IP 1: " + self.ext_ip_1)
            else:
                self.parameterException(self.EXT_IP_1)

            if self.EXT_IP_2 in env:
                self.ext_ip_2 = env[self.EXT_IP_2]
                self.logger("External IP 1: " + self.ext_ip_2)
            else:
                self.parameterException(self.EXT_IP_2)

        except Exception as e:
            self.logger("--Parameter Missing Exception-- ", e)    
            
    def update_vpc_routing_table_route(self,cmd):   
        self.logger("Calling update vpc routing table route method VIP.")    
        self.logger("VPC ID: " + self.vpc_id) 
        self.logger("VPC URL: " + self.vpc_url) 
        self.logger("VPC self.ext_ip_1: " + self.ext_ip_1) 
        self.logger("VPC self.ext_ip_2: " + self.ext_ip_2) 
        self.logger("VPC self.api_key: " + self.apikey)
        list_tables = ''
        authenticator = IAMAuthenticator(self.apikey, url='https://iam.cloud.ibm.com')
        self.service = VpcV1(authenticator=authenticator)
        self.service.set_service_url(self.vpc_url)
        try:
            if self.service.list_vpc_routing_tables(self.vpc_id).get_result() is not None:
                list_tables = self.service.list_vpc_routing_tables(self.vpc_id).get_result()['routing_tables']
                self.logger("Here 1.3")
        except Exception as e:
            print("List VPC routing table failed with status code " + str(e.code) + ": " + e.message)
            return False
        update_done = False
        self.logger("Iterating through below Table Name and Table ID!!")
        self.logger (list_tables)
        for table in list_tables:
            ingress_routing_table = False
            #if update_done:
            #    break
            self.logger("Name: " + table['name'] + "\tID: " +  table['id'])
            table_id_temp = table['id']
            if table['route_direct_link_ingress'] or table['route_transit_gateway_ingress']:
                ingress_routing_table =True 
            list_routes = self.service.list_vpc_routing_table_routes(vpc_id= self.vpc_id, routing_table_id=table_id_temp)
            routes = list_routes.get_result()['routes']
            for route in routes:
                route_id_temp = route['id']
                self.logger ("Route ID: " + route['id'])
                self.logger ("Next hop address of above Route ID: " + str(route['next_hop']))
                if route['next_hop']['address'] == self.ext_ip_1 or route['next_hop']['address'] == self.ext_ip_2:
                    self.logger (cmd)
                    if cmd == "GET":
                        self.logger("GET Command")
                        print (route['next_hop']['address'])
                        update_done = False
                        return update_done
                    self.find_the_current_and_next_hop_ip(route['next_hop']['address'])
                    self.logger("VPC routing table route found!!, ID: %s, Name: %s, zone: %s, Next_Hop:%s, Destination:%s " % (route['id'], route['name'], route['zone']['name'], route['next_hop']['address'], route['destination']))
                    self.logger (route)
                    route_next_hop_prototype_model = {'address': self.update_next_hop_vsi}
                    # Construct a dict representation of a RoutePatch model
                    route_patch_model = {}
                    route_patch_model['advertise'] = route['advertise']
                    route_patch_model['name'] = route['name']
                    route_patch_model['next_hop'] = route_next_hop_prototype_model
                    route_patch_model['priority'] = route['priority']

                    self.logger("Update old route: " + route_id_temp)
                    #for same AZ failover we can patch the nexthop using update
                    if route['zone']['name'] == self.vsi_local_az or not ingress_routing_table:
                        
                        self.logger("Same AZ Fail over AZ: " + self.vsi_local_az)
                        update_vpc_routing_table_route_response = self.service.update_vpc_routing_table_route(vpc_id=self.vpc_id, routing_table_id=table_id_temp, id=route_id_temp,route_patch=route_patch_model)
                        result = update_vpc_routing_table_route_response.get_result()
                        self.logger("Update old route result: ")
                        self.logger (result)
                    else:
                        #Delete old route
                        zone_identity_model = {'name': self.vsi_local_az}
                        self.service.delete_vpc_routing_table_route(vpc_id=self.vpc_id, routing_table_id=table_id_temp, id=route_id_temp)
                        self.logger("Deleted old route: " + route_id_temp)
                        #Create new route
                        create_vpc_routing_table_route_response = self.service.create_vpc_routing_table_route(vpc_id=self.vpc_id, routing_table_id=table_id_temp, destination=route['destination'], zone=zone_identity_model, action='deliver', next_hop=route_next_hop_prototype_model, name=route['name'])
                        route = create_vpc_routing_table_route_response.get_result()
                        self.logger("Created new route: " + route['id'])
                    update_done = True
        return update_done       
            
    def logger(self, message):
        if self.DEBUG:
            print (message)

    def find_the_current_and_next_hop_ip(self, route_address):
        if route_address == self.ext_ip_1:
            #To be updated with IP address.
            self.update_next_hop_vsi = self.ext_ip_2
            #Current Hop IP address.
            self.next_hop_vsi = self.ext_ip_1
        else:
            #To be updated with IP address.
            self.update_next_hop_vsi = self.ext_ip_1
            #Current IP address.
            self.next_hop_vsi = self.ext_ip_2
        self.logger("Current next hop IP is: " + self.next_hop_vsi)
        self.logger("Update next hop IP to: " + self.update_next_hop_vsi)
                
def fail_over(cmd):
    haFailOver = HAFailOver()
    #self.logger("Request received from: " + remote_addr)
    made_update = haFailOver.update_vpc_routing_table_route(cmd)
    #return "Updated Custom Route: " + str(made_update)

if __name__ == "__main__":
    sys_argv_length=len(sys.argv)-1
    if sys_argv_length == 1:
        fail_over(sys.argv[1])
    else:
        print ("Error must provide parameter usage: ibm-cloud-pacemaker-fail-over.py GET|SET")

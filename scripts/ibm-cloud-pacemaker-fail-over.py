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
    logger = ''

    service = None
    
    def __init__(self):
        print("--------Constructor---------")
        if self.apikey is None:
            print("--------parse_config")
            self.parse_config()
        #authenticator = IAMAuthenticator(self.apikey, url='https://iam.cloud.ibm.com')
        #self.service = VpcV1(authenticator=authenticator)
        #self.service.set_service_url(self.vpc_url)
        #access_token = self.get_token()
        #print("Initialized VPC service!!" + access_token)
    

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
            print(f"Error getting token. {error}")
            raise

    def parameterException(missingParameter):
        raise Exception("Please!!! provide " + missingParameter)
         
    def parse_config(self):
        try:
            print (env)
            if self.API_KEY in env:
                self.apikey = env[self.API_KEY]
                print(self.API_KEY + ": " + self.apikey)
            else:
                self.parameterException(self.API_KEY)
            
            if self.VPC_ID in env:
                self.vpc_id = env[self.VPC_ID]
                print(self.VPC_ID + ": " + self.vpc_id)
            else:
                self.parameterException(self.VPC_ID)
            
            if self.VPC_URL in env:
                self.vpc_url = env[self.VPC_URL]
                print(self.VPC_URL + ": " + self.vpc_url)
            else:
                self.parameterException(self.VPC_URL)

            #if self.ZONE in env:
            #    self.zone = env[self.ZONE]
            #    print(self.ZONE + ": " + self.zone)
            #else:
            #    self.parameterException(self.ZONE)
            

            if self.EXT_IP_1 in env:
                self.ext_ip_1 = env[self.EXT_IP_1]
                print("External IP 1: " + self.ext_ip_1)
            else:
                self.parameterException(self.EXT_IP_1)

            if self.EXT_IP_2 in env:
                self.ext_ip_2 = env[self.EXT_IP_2]
                print("External IP 1: " + self.ext_ip_2)
            else:
                self.parameterException(self.EXT_IP_2)

        except Exception as e:
            print("--Parameter Missing Exception-- ", e)    
            
    def update_vpc_routing_table_route(self, old_addr, new_addr):   
        print("Calling update vpc routing table route method.")    
        print("VPC ID: " + self.vpc_id) 
        print("VPC URL: " + self.vpc_url) 
        print("VPC self.ext_ip_1: " + self.ext_ip_1) 
        print("VPC self.ext_ip_2: " + self.ext_ip_2) 
        list_tables = ''
        authenticator = IAMAuthenticator(self.apikey, url='https://iam.cloud.ibm.com')
        self.service = VpcV1(authenticator=authenticator)
        self.service.set_service_url(self.vpc_url)
        if self.service.list_vpc_routing_tables(self.vpc_id).get_result() is not None:
            list_tables = self.service.list_vpc_routing_tables(self.vpc_id).get_result()['routing_tables']
        update_done = False
        print("Iterating through below Table Name and Table ID!!")
        for table in list_tables:
            if update_done:
                break
            print("Name: " + table['name'] + "\tID: " +  table['id'])
            table_id_temp = table['id']
            list_routes = self.service.list_vpc_routing_table_routes(vpc_id= self.vpc_id, routing_table_id=table_id_temp)
            routes = list_routes.get_result()['routes']
            for route in routes:
                route_id_temp = route['id']
                print ("Route ID: " + route['id'])
                print ("Next hop address of above Route ID: " + str(route['next_hop']))
                if route['next_hop']['address'] == self.ext_ip_1 or route['next_hop']['address'] == self.ext_ip_2:
                    self.find_the_current_and_next_hop_ip(route['next_hop']['address'])
                    print("VPC routing table route found!!, ID: %s, Name: %s, zone: %s, Next_Hop:%s, Destination:%s " % (route['id'], route['name'], route['zone']['name'], route['next_hop']['address'], route['destination']))
                    print (route)
                    zone_identity_model = {'name': route['zone']['name']}
                    route_next_hop_prototype_model = {'address': self.update_next_hop_vsi}
                    # Construct a dict representation of a RoutePatch model
                    route_patch_model = {}
                    route_patch_model['advertise'] = route['advertise']
                    route_patch_model['name'] = route['name']
                    route_patch_model['next_hop'] = route_next_hop_prototype_model
                    route_patch_model['priority'] = route['priority']

                    print("Update old route: " + route_id_temp)
                    #for same AZ failover we can patch the nexthop using update 
                    update_vpc_routing_table_route_response = self.service.update_vpc_routing_table_route(vpc_id=self.vpc_id, routing_table_id=table_id_temp, id=route_id_temp,route_patch=route_patch_model)
                    result = update_vpc_routing_table_route_response.get_result()
                    print("Update old route result: ")
                    print (result)
                    #Delete old route
                    #self.service.delete_vpc_routing_table_route(vpc_id=self.vpc_id, routing_table_id=table_id_temp, id=route_id_temp)
                    #print("Deleted old route: " + route_id_temp)
                    #Create new route
                    #create_vpc_routing_table_route_response = self.service.create_vpc_routing_table_route(vpc_id=self.vpc_id, routing_table_id=table_id_temp, destination=route['destination'], zone=zone_identity_model, action='deliver', next_hop=route_next_hop_prototype_model, name=route['name'])
                    #route = create_vpc_routing_table_route_response.get_result()
                    #print("Created new route: " + route['id'])
                    update_done = True
        return update_done       
            
            
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
        print("Current next hop IP is: " + self.next_hop_vsi)
        print("Update next hop IP to: " + self.update_next_hop_vsi)
                
def fail_over(old_addr,new_addr):
    haFailOver = HAFailOver()
    #print("Request received from: " + remote_addr)
    made_update = haFailOver.update_vpc_routing_table_route(old_addr,new_addr)
    print('Updated routing table route!!')
    #return "Updated Custom Route: " + str(made_update)

if __name__ == "__main__":
    fail_over("10.251.0.4","10.251.0.6");
 

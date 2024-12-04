#!/usr/bin/env python3 

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
from ibm_cloud_sdk_core.authenticators import BearerTokenAuthenticator
from os import environ as env
from dotenv import load_dotenv
import http.client
import json


load_dotenv("env")


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
    HTTP = "HTTP"
    HTTPS = "HTTPS"
    METADATA_VERSION = "2022-03-01"
    METADATA_HOST = "api.metadata.cloud.ibm.com"
    METADATA_PATH = "/instance_identity/v1/"
    apikey = None
    vpc_url = ""
    vpc_id = ""
    table_id = ""
    route_id = ""
    zone = ""
    next_hop_vsi = ""
    update_next_hop_vsi = ""
    mgmt_ip_1 = ""
    mgmt_ip_2 = ""
    ext_ip_1 = ""
    ext_ip_2 = ""
    DEBUG = True
    # DEBUG = True
    service = None

    def __init__(self):
        self.logger("--------Constructor---------")
        if self.apikey is None:
            self.logger("--------parse_config")
            self.parse_config()
        # authenticator = IAMAuthenticator(self.apikey, url='https://iam.cloud.ibm.com')
        # self.service = VpcV1(authenticator=authenticator)
        # self.service.set_service_url(self.vpc_url)
        # access_token = self.get_token()
        # self.logger("Initialized VPC service!!" + access_token)

    def get_token(self):
        if self.apikey is not None:
            self.logger("------apikey path")
            return self._get_token_from_apikey()
        else:
            self.logger("------trusted profile path")
            return self._get_token_from_tp()
        
    def _get_token_from_tp(self):
        connection = self._get_metadata_connection()
        return self._get_iam_token_from_tp(connection)
        
    def _get_iam_token_from_tp(self, connection: http.client.HTTPSConnection):
        metadata_token = self._get_metadata_token(connection)
        connection.request("POST", 
                           self._get_metadata_iam_token_path(), 
                           headers=self._get_metadata_headers_iam(metadata_token))
        response = json.loads(connection.getresponse().read().decode("utf-8"))
        if 'access_token' not in response:
            self.logger(response)
            self.logger('Can not get access token from trusted profile. Review if a TP is bound to the instance.')
            raise Exception('Can not get access token from trusted profile. Review if a TP is bound to the instance.')
        return f"Bearer {response['access_token']}"

    def _get_metadata_token(self, connection: http.client.HTTPSConnection):
        connection.request("PUT", 
                           self._get_metadata_token_path(),
                           body=self._get_metadata_body(), 
                           headers=self._get_metadata_headers())
        return json.loads(connection.getresponse().read().decode("utf-8"))['access_token']
        
    def _get_metadata_token_path(self):
        return f"{self.METADATA_PATH}token?version={self.METADATA_VERSION}"
    
    def _get_metadata_iam_token_path(self):
        return f"{self.METADATA_PATH}iam_token?version={self.METADATA_VERSION}"

    def _get_metadata_body(self):
        return json.dumps({
            "expires_in": 3600
        })

    def _get_metadata_headers(self) -> dict:
        return {
            'Metadata-Flavor': 'ibm',
            'Accept': 'application/json'
        }
    
    def _get_metadata_headers_iam(self, metadata_token) -> dict:
        headers = self._get_metadata_headers()
        headers['Authorization'] = f"Bearer {metadata_token}"
        return headers
        
    def _get_metadata_connection(self):
        connection = None
        if self._check_connectivity(self.METADATA_HOST, 80):
            connection = http.client.HTTPConnection(self.METADATA_HOST)
        elif self._check_connectivity(self.METADATA_HOST, 443):
            connection = http.client.HTTPSConnection(self.METADATA_HOST)
        if connection is None:
            self.logger("Activate metadata at VSI instance please! and be sure that a TP is bound to the instance")
            raise Exception("Activate metadata at VSI instance please! and be sure that a TP is bound to the instance")
        return connection        

    def _get_token_from_apikey(self):
        # URL for token
        conn = http.client.HTTPSConnection("iam.cloud.ibm.com")
        # Payload for retrieving token. Note: An API key will need to be generated and replaced here
        payload = (
            "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey="
            + self.apikey
            + "&response_type=cloud_iam"
        )

        # Required headers
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
            "Cache-Control": "no-cache",
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
            return json_res["token_type"] + " " + json_res["access_token"]

        # If an error happens while retrieving token
        except Exception as error:
            self.logger(f"Error getting token. {error}")
            raise

    def _check_connectivity(self, ip, port):
        import socket
        try:
            with socket.create_connection((ip, port), 5):
                self.logger(f"Successfully connected to {ip}:{port}")
                return True
        except socket.timeout:
            self.logger(f"Connection to {ip}:{port} timed out.")
        except socket.error as e:
            self.logger(f"Failed to connect to {ip}:{port}: {e}")
        return False

    def parameterException(missingParameter):
        raise Exception("Please!!! provide " + missingParameter)

    def parse_config(self):
        try:
            self.logger(env)
            if self.API_KEY in env:
                self.apikey = env[self.API_KEY]
                self.logger(self.API_KEY + ": " + self.apikey)

            if self.VPC_ID in env:
                self.vpc_id = env[self.VPC_ID]
                self.vpc_id = env[self.VPC_ID]
                self.logger(self.VPC_ID + ": " + self.vpc_id)

            if self.VPC_URL in env:
                self.vpc_url = env[self.VPC_URL]
                self.logger(self.VPC_URL + ": " + self.vpc_url)
            else:
                self.parameterException(self.VPC_URL)

            if self.VSI_LOCAL_AZ in env:
                self.vsi_local_az = env[self.VSI_LOCAL_AZ]
                self.logger("VSI Local AZ: " + self.vsi_local_az)
            else:
                self.vsi_local_az = ""

            if self.EXT_IP_1 in env:
                self.ext_ip_1 = env[self.EXT_IP_1]
                self.logger("External IP 1: " + self.ext_ip_1)

            if self.EXT_IP_2 in env:
                self.ext_ip_2 = env[self.EXT_IP_2]
                self.logger("External IP 1: " + self.ext_ip_2)

        except Exception as e:
            self.logger(e)

    def update_vpc_fip(self, cmd, vni_id, fip_id):
        self.logger("Calling update vpc routing table route method VIP.")
        self.logger("VPC ID: " + self.vpc_id)
        self.logger("VPC URL: " + self.vpc_url)
        self.logger("VPC self.ext_ip_1: " + self.ext_ip_1)
        self.logger("VPC self.ext_ip_2: " + self.ext_ip_2)
        self.logger("VPC self.api_key: " + str(self.apikey))
        self.logger("cmd: " + cmd)
        authenticator = BearerTokenAuthenticator(self.get_token())
        self.service = VpcV1(authenticator=authenticator)
        self.service.set_service_url(self.vpc_url)
        ret = ""
        try:
            if cmd == "remove":
                ret = self.service.remove_network_interface_floating_ip(
                    vni_id, fip_id
                ).get_result()
            if cmd == "add":
                ret = self.service.add_network_interface_floating_ip(
                    vni_id, fip_id
                ).get_result()
        except Exception as e:
            print(e)
            raise e
        print(ret)
        return True

    def update_vpc_routing_table_route(self, cmd):
        self.logger("Calling update vpc routing table route method VIP.")
        self.logger("VPC ID: " + self.vpc_id)
        self.logger("VPC URL: " + self.vpc_url)
        self.logger("VPC self.ext_ip_1: " + self.ext_ip_1)
        self.logger("VPC self.ext_ip_2: " + self.ext_ip_2)
        self.logger("VPC self.api_key: " + str(self.apikey))
        list_tables = ""
        authenticator = BearerTokenAuthenticator(self.get_token())
        self.service = VpcV1(authenticator=authenticator)
        self.service.set_service_url(self.vpc_url)
        try:
            if (
                self.service.list_vpc_routing_tables(self.vpc_id).get_result()
                is not None
            ):
                list_tables = self.service.list_vpc_routing_tables(
                    self.vpc_id
                ).get_result()["routing_tables"]
                self.logger("Here 1.3")
        except Exception as e:
            print(e)
            return False
        update_done = False
        self.logger("Iterating through below Table Name and Table ID!!")
        self.logger(list_tables)
        for table in list_tables:
            ingress_routing_table = False
            # if update_done:
            #    break
            self.logger("Name: " + table["name"] + "\tID: " + table["id"])
            table_id_temp = table["id"]
            if (
                table["route_direct_link_ingress"]
                or table["route_transit_gateway_ingress"]
            ):
                ingress_routing_table = True
            list_routes = self.service.list_vpc_routing_table_routes(
                vpc_id=self.vpc_id, routing_table_id=table_id_temp
            )
            routes = list_routes.get_result()["routes"]
            for route in routes:
                route_id_temp = route["id"]
                self.logger("Route ID: " + route["id"])
                self.logger(
                    "Next hop address of above Route ID: " + str(route["next_hop"])
                )
                if (
                    route["next_hop"]["address"] == self.ext_ip_1
                    or route["next_hop"]["address"] == self.ext_ip_2
                ):
                    if cmd == "GET":
                        self.logger("GET Command")
                        print(route["next_hop"]["address"])
                        update_done = False
                        return update_done
                    self.find_the_current_and_next_hop_ip(route["next_hop"]["address"])
                    self.logger(
                        "VPC routing table route found!!, ID: %s, Name: %s, zone: %s, Next_Hop:%s, Destination:%s "
                        % (
                            route["id"],
                            route["name"],
                            route["zone"]["name"],
                            route["next_hop"]["address"],
                            route["destination"],
                        )
                    )
                    self.logger(route)
                    route_next_hop_prototype_model = {
                        "address": self.update_next_hop_vsi
                    }
                    # Construct a dict representation of a RoutePatch model
                    route_patch_model = {}
                    route_patch_model["advertise"] = route["advertise"]
                    route_patch_model["name"] = route["name"]
                    route_patch_model["next_hop"] = route_next_hop_prototype_model
                    route_patch_model["priority"] = route["priority"]
                    zone_identity_model = {"name": route["zone"]["name"]}
                    # for same AZ failover we can patch the nexthop using update
                    if (
                        route["zone"]["name"] == self.vsi_local_az
                        or not ingress_routing_table
                    ):
                        self.logger("Update old route: " + route_id_temp)
                        self.logger("Same AZ Fail over AZ: " + self.vsi_local_az)
                        update_vpc_routing_table_route_response = (
                            self.service.update_vpc_routing_table_route(
                                vpc_id=self.vpc_id,
                                routing_table_id=table_id_temp,
                                id=route_id_temp,
                                route_patch=route_patch_model,
                            )
                        )
                        result = update_vpc_routing_table_route_response.get_result()
                        self.logger("Update old route result: ")
                        self.logger(result)
                    else:
                        # Delete old route
                        try:
                            if self.vsi_local_az != "":
                                zone_identity_model = {"name": self.vsi_local_az}
                            self.service.delete_vpc_routing_table_route(
                                vpc_id=self.vpc_id,
                                routing_table_id=table_id_temp,
                                id=route_id_temp,
                            )
                            self.logger("Deleted old route: " + route_id_temp)
                            # Create new route
                            create_vpc_routing_table_route_response = (
                                self.service.create_vpc_routing_table_route(
                                    vpc_id=self.vpc_id,
                                    routing_table_id=table_id_temp,
                                    destination=route["destination"],
                                    zone=zone_identity_model,
                                    action="deliver",
                                    next_hop=route_next_hop_prototype_model,
                                    name=route["name"],
                                    advertise=route["advertise"],
                                )
                            )
                            route = create_vpc_routing_table_route_response.get_result()
                            self.logger("Created new route: " + route["id"])
                        except Exception as e:
                            print(e)

                        update_done = True
        return update_done

    def logger(self, message):
        if self.DEBUG:
            print(message)

    def find_the_current_and_next_hop_ip(self, route_address):
        if route_address == self.ext_ip_1:
            # To be updated with IP address.
            self.update_next_hop_vsi = self.ext_ip_2
            # Current Hop IP address.
            self.next_hop_vsi = self.ext_ip_1
        else:
            # To be updated with IP address.
            self.update_next_hop_vsi = self.ext_ip_1
            # Current IP address.
            self.next_hop_vsi = self.ext_ip_2
        self.logger("Current next hop IP is: " + self.next_hop_vsi)
        self.logger("Update next hop IP to: " + self.update_next_hop_vsi)


def fail_over(cmd):
    haFailOver = HAFailOver()
    # self.logger("Request received from: " + remote_addr)
    made_update = haFailOver.update_vpc_routing_table_route(cmd)
    return "Updated Custom Route: " + str(made_update)


def fail_over_fip(cmd, vni_id, fip_id):
    haFailOver = HAFailOver()
    haFailOver.update_vpc_fip(cmd, vni_id, fip_id)


def usage_fip():
    print("{0} [FIP] [CMD add|remove] [VNI_ID] [FIP_ID]".format(sys.argv[0]))
    print("\n")


if __name__ == "__main__":
    if len(sys.argv) > 2:
        if sys.argv[1] == "FIP":
            fail_over_fip(sys.argv[2], sys.argv[3], sys.argv[4])
        elif sys.argv[1] == "ROUTE":
            fail_over(sys.argv[2])
    else:
        print(
            "Error must provide parameter usage: ibm_cloud_pacemaker_fail_over.py ROUTE GET|SET"
        )
        usage_fip()

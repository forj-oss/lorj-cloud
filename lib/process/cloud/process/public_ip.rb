# encoding: UTF-8

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# It requires Core objects to be defined + default ForjProcess functions.

# rubocop: disable Style/ClassAndModuleChildren

# Addresses management
class CloudProcess
  # Process Handler functions
  def forj_get_or_assign_public_address(sCloudObj, hParams)
    # Function which to assign a public IP address to a server.
    server_name = hParams[:server, :name]

    PrcLib.state("Searching public IP for server '%s'", server_name)
    addresses = controller_query(sCloudObj, :server_id => hParams[:server, :id])
    if addresses.length == 0
      assign_address(sCloudObj, hParams)
    else
      addresses[0]
    end
  end

  # Function to query the list of addresses for one server
  def forj_query_public_address(sCloudObj, sQuery, hParams)
    server_name = hParams[:server, :name]
    ssl_error_obj = SSLErrorMgt.new
    begin
      info = {
        :notfound => "No %s for '%s' found",
        :checkmatch => "Found 1 %s. checking exact match for server '%s'.",
        :nomatch => "No %s for '%s' match",
        :found => "Found %s '%s' for #{server_name}.",
        :more => "Found several %s. Searching for '%s'.",
        :items => :public_ip
      }
      #  list = controller_query(sCloudObj, sQuery)
      #  query_single(sCloudObj, list, sQuery, server_name, info)
      query_single(sCloudObj, sQuery, server_name, info)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  # Function to get the IP address
  def forj_get_public_address(sCloudObj, sId, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sId)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end
end

# SERVER Addresses Object
# Object representing the list of IP addresses attached to a server.
class Lorj::BaseDefinition
  define_obj(:public_ip,
             :create_e => :forj_get_or_assign_public_address,
             :query_e  => :forj_query_public_address,
             :get_e    => :forj_get_public_address
            #      :update_e   => :forj_update_address
            #      :delete_e   => :forj_delete_address
            )

  obj_needs :CloudObject,  :compute_connection
  obj_needs :CloudObject,  :server

  def_attribute :server_id
  def_attribute :public_ip
  undefine_attribute :name # No name to extract
end

# Internal Process function
class CloudProcess
  def assign_address(sCloudObj, hParams)
    name = hParams[:server, :name]
    begin
      PrcLib.state('Getting public IP for server %s', name)
      ip_address = controller_create(sCloudObj)
      if ip_address.empty?
        PrcLib.error("Unable to assign a public IP to server '%s'", name)
        return ip_address
      end
      PrcLib.info("Public IP '%s' for server '%s' "\
                  'assigned.', ip_address[:public_ip], name)
   rescue => e
     PrcLib.fatal(1, "Unable to assign a public IP to server '%s'", name, e)
    end
    ip_address
  end
end

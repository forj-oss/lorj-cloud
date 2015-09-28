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

# Network Management
class CloudProcess
  # Process Create handler
  def forj_get_or_create_network(sCloudObj, hParams)
    PrcLib.state("Searching for network '%s'", hParams[:network_name])
    networks = find_network(sCloudObj, hParams)
    if networks.length == 0
      network = create_network(sCloudObj, hParams)
    else
      network = networks[0]
    end
    register(network)

    # Attaching if missing the subnet.
    # Creates an object subnet, attached to the network.
    params = {}
    unless hParams[:subnetwork_name]
      params[:subnetwork_name] = 'sub-' + hParams[:network_name]
    end

    process_create(:subnetwork, params)

    network
  end

  # Process Delete handler
  def forj_delete_network(sCloudObj, hParams)
    oProvider.delete(sCloudObj, hParams)
  rescue => e
    PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
  end

  def forj_get_network(sCloudObj, sID, hParams)
    oProvider.get(sCloudObj, sID, hParams)
  rescue => e
    PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
  end
end

# Network Object
# Identify the network
class Lorj::BaseDefinition
  define_obj(:network,
             :create_e => :forj_get_or_create_network,
             :query_e => :controller_query,
             :get_e => :forj_get_network,
             :delete_e => :forj_delete_network
            )
  obj_needs :CloudObject,  :network_connection
  obj_needs :data,         :network_name, :for => [:create_e]

  obj_needs_optional
  obj_needs :data, :subnetwork_name, :for => [:create_e]

  # Any attribute are queriable
  def_attribute :external # true if network is external or not.
end

# Network Process internal functions #
class CloudProcess
  # Network creation
  # It returns:
  # nil or Provider Object
  def create_network(sCloudObj, hParams)
    name = hParams[:network_name]
    begin
      PrcLib.state("Creating network '%s'", name)
      network = controller_create(sCloudObj)
      PrcLib.info("Network '%s' created", network[:name])
    rescue => e
      PrcLib.fatal(1, "Unable to create network '%s'", name, e)
    end
    network
  end

  # Search for a network from his name.
  # Name may be unique in project context, but not in the cloud system
  # It returns:
  # nil or Provider Object
  def find_network(sCloudObj, hParams)
    query = { :name => hParams[:network_name] }

    query_single(sCloudObj, query, hParams[:network_name])
  rescue => e
    PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
  end
end

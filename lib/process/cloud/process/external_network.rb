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

# External network process attached to a network
class CloudProcess
  def forj_get_or_create_ext_net(sCloudObj, hParams)
    PrcLib.state("Checking router '%s' gateway", hParams[:router, :name])

    router_obj = hParams[:router]
    router_name = hParams[:router, :name]
    network_id = hParams[:router, :gateway_network_id]
    if network_id
      external_network = forj_query_external_network(sCloudObj,
                                                     { :id => network_id },
                                                     hParams)
      PrcLib.info("Router '%s' is attached to the "\
                  "external gateway '%s'.", router_name,
                  external_network[:name])
    else
      PrcLib.info("Router '%s' needs to be attached to an "\
                  'external gateway.', router_name)
      PrcLib.state('Attaching')
      external_network = forj_query_external_network(:network, {}, hParams)
      if !external_network.empty?
        router_obj[:gateway_network_id] = external_network[:id]
        controller_update(:router, router_obj)
        PrcLib.info("Router '%s' attached to the "\
                    "external network '%s'.",
                    router_name, external_network[:name])
      else
        PrcLib.fatal(1, "Unable to attach router '%s' to an external gateway. "\
                        'Required for boxes to get internet access. ',
                     get_data(:router, :name))
      end
    end

    # Need to keep the :network object as :external_network object type.
    external_network.type = sCloudObj
    external_network
  end

  def forj_query_external_network(_sCloudObj, sQuery, _hParams)
    PrcLib.state('Identifying External gateway')
    begin
      # Searching for external network
      query = sQuery.merge(:external => true)
      info = {
        :notfound => 'No external network found',
        :checkmatch => 'Found 1 %s. Checking if it is an %s.',
        :nomatch => 'No %s identified as %s match',
        :found => "Found external %s '%s'.",
        :more => 'Found several %s. Searching for the first one to be an %s.'
      }
      networks = query_single(:network, query, 'external network', info)
      return Lorj::Data.new if networks.length == 0
      networks[0]
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
  end
end

# Identify an external network thanks to the network router.
class Lorj::BaseDefinition
  define_obj(:external_network,

             :create_e => :forj_get_or_create_ext_net,
             :query_e => :forj_query_external_network
            )

  obj_needs :CloudObject,  :network_connection
  obj_needs :CloudObject,  :router
end

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

# ---------------------------------------------------------------------------
# Router management
# ---------------------------------------------------------------------------
class CloudProcess
  # Process Create handler
  def forj_get_or_create_router(_sCloudObj, hParams)
    sub_net_obj = hParams[:subnetwork]

    if hParams[:router_name].nil?
      router_name = format('router-%s', hParams[:network, :name])
    else
      router_name = hParams[:router_name]
    end

    _get_router(router_name, sub_net_obj, hParams)
  end

  def _get_router(router_name, sub_net_obj, hParams)
    router_port = get_router_interface_attached(:port, hParams)

    if router_port.nil? || router_port.length == 0
      # Trying to get router
      router = get_router(router_name)
      router = create_router(router_name) if router.empty?
      create_router_interface(sub_net_obj, router) if router
    else
      router = query_router_from_port(router_port[0], hParams)
    end
    router
  end
end

# Router Object
# Identify the router of a network.
class Lorj::BaseDefinition
  define_obj(:router,

             :create_e => :forj_get_or_create_router,
             #         :query_e    => :forj_query_router,
             #         :get_e      => :forj_get_router,
             :update_e => :controller_update
            #         :delete_e   => :forj_delete_router
            )
  obj_needs :CloudObject,  :network_connection
  obj_needs :CloudObject,  :network,             :for => [:create_e]
  obj_needs :CloudObject,  :subnetwork,          :for => [:create_e]
  obj_needs_optional
  obj_needs :data, :router_name, :for => [:create_e]

  def_attribute :gateway_network_id
end

# Port Object
# Identify port attached to network
class Lorj::BaseDefinition
  define_obj :port, :nohandler => true

  obj_needs :CloudObject, :network_connection
  def_attribute :device_id

  def_attribute :network_id
  def_attribute :device_owner
end

# Router interface Object
# Identify interface attached to a router
# This object will probably be moved to controller task
# To keep the network model more generic.
class Lorj::BaseDefinition
  # No process handler defined. Just Controller object
  define_obj :router_interface, :nohandler => true

  obj_needs :CloudObject,  :network_connection
  obj_needs :CloudObject,  :router,              :for => [:create_e]
  obj_needs :CloudObject,  :subnetwork,          :for => [:create_e]

  undefine_attribute :name
  undefine_attribute :id
end

# Router Process internal functions
class CloudProcess
  def get_router(name)
    PrcLib.state("Searching for router '%s'", name)
    begin
      query = { :name => name }
      routers = query_single(:router, query, name)
      return Lorj::Data.new if routers.length == 0
      register(routers[0])
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
  end

  def create_router(router_name, oExternalNetwork = nil)
    begin
      if oExternalNetwork
        ext_net = get_data(oExternalNetwork, :name)
        PrcLib.state("Creating router '%s' attached to the external "\
                     "Network '%s'", router_name, ext_net)
        config[:external_gateway_id] = get_data(oExternalNetwork, :id)
      else
        PrcLib.state("Creating router '%s' without external Network",
                     router_name)
      end

      router = controller_create(:router, :router_name => router_name)
      if oExternalNetwork
        PrcLib.info("Router '%s' created and attached to the external "\
                    "Network '%s'.", router_name, ext_net)
      else
        PrcLib.info("Router '%s' created without external Network.",
                    router_name)
      end
    rescue => e
      PrcLib.error "Unable to create '%s' router\n%s\n%s", router_name,
                   e.message, e.backtrace.join("\n")
    end
    router
  end

  def delete_router(net_conn_obj, router_obj)
    PrcLib.state("Deleting router '%s'", router.name)
    begin
      #################
      provider_delete_router(net_conn_obj, router_obj)
    # net_conn_obj.routers.get(router.id).destroy
    rescue => e
      PrcLib.error("Unable to delete '%s' router ID", router_id, e)
    end
  end

  def query_router_from_port(router_port, _hParams)
    query = { :id => router_port[:device_id] }
    info = {
      :notfound => 'No %s for port ID %s found',
      :checkmatch => 'Found 1 %s. Checking exact match for port ID %s.',
      :nomatch => 'No %s for port ID %s match',
      :found => "Found %s '%s' from port ID #{router_port[:device_id]}.",
      :more => 'Found several %s. Searching for port ID %s.'
    }
    routers = query_single(:router, query, router_port[:device_id], info)
    return Lorj::Data.new if routers.length == 0
    register(routers[0])
  end

  # TODO: Move router interface management to hpcloud controller.
  # Router interface to connect to the network
  def create_router_interface(oSubnet, router_obj)
    PrcLib.state("Attaching subnet '%s' to router '%s'",
                 oSubnet[:name], router_obj[:name])
    begin
      controller_create(:router_interface)

    #################
    # provider_add_interface()
    # router_obj.add_interface(oSubnet.id, nil)
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
  end

  def delete_router_interface(oSubnet, router_obj)
    PrcLib.state("Removing subnet '%s' from router '%s'",
                 oSubnet.name, router_obj.name)
    subnet_id = oSubnet.id
    begin
      #################
      router_obj.remove_interface(subnet_id)
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
  end

  # Function to get the router ID in the network
  # from the list of routers found.
  # Query ports devices.
  def get_router_interface_attached(sCloudObj, hParams)
    name = hParams[:network, :name]
    PrcLib.state("Searching for router port attached to the network '%s'", name)
    routers = controller_query(:router, {})
    routers.each do |router|
      begin
        router_name = router[:name]
        # Searching for router port attached
        #################
        query = { :network_id => hParams[:network, :id],
                  :device_id => router[:id] }
        info = {
          :notfound => "Network '#{name}' not attached to router "\
                       "'#{router_name}'",
          :checkmatch => 'Found 1 router %s. '\
                               "Checking exact match for network '%s'.",
          :nomatch => "No router %s for network '%s' match",
          :found => "Found router %s ID (#{router_name}) %s attached to "\
                    "network '#{name}'.",
          :more => "Found several router %s. Searching for network '%s'.",
          :items => [:id]
        }
        interfaces = query_single(sCloudObj, query, name, info)
        return interfaces unless interfaces.length == 0
      rescue => e
        PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
      end
    end
  end

  # Gateway management
  def get_gateway(net_conn_obj, name)
    return nil if !name || !net_conn_obj

    PrcLib.state("Getting gateway '%s'", name)
    networks = net_conn_obj
    begin
      netty = networks.get(name)
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
    PrcLib.state("Found gateway '%s'", name) if netty
    PrcLib.state("Unable to find gateway '%s'", name) unless netty
    netty
  end

  def query_external_network(_hParams)
    PrcLib.state('Identifying External gateway')
    begin
      # Searching for router port attached
      #################
      query = { :router_external => true }
      networks = controller_query(:network, query)
      case networks.length
      when 0
        PrcLib.info('No external network')
        Lorj::Data.new
      when 1
        PrcLib.info("Found external network '%s'.", networks[0, :name])
        networks[0]
      else
        PrcLib.warn('Found several external networks. Selecting the '\
                    "first one '%s'", networks[0, :name])
        networks[0]
      end
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
  end
end

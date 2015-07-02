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

# This class describes how to process some actions, and will do everything prior
# this task to make it to work.

require 'fog' # We use fog to access HPCloud

hpcloud_path = File.expand_path(File.dirname(__FILE__))

load File.join(hpcloud_path, 'hpcloud_declare.rb')
load File.join(hpcloud_path, 'hpcloud_generic.rb')
load File.join(hpcloud_path, 'hpcloud_query.rb')
load File.join(hpcloud_path, 'hpcloud_refresh.rb')

load File.join(hpcloud_path, 'compute.rb')
load File.join(hpcloud_path, 'network.rb')
load File.join(hpcloud_path, 'security_groups.rb')

# Following class describe how FORJ should handle HP Cloud objects.
# Except Cloud connection, all HPCloud objects management are described/called
# in HP* modules.
class HpcloudController # rubocop: disable Metrics/ClassLength
  # Ready to convert the controller in more maintainable code
  # Only refresh is currently used.
  def self.def_cruds(*crud_types)
    crud_types.each do |crud_type|
      case crud_type
      when :create, :delete, :refresh
        base_method(crud_type)
      when :query, :get
        query_method(crud_type)
      when :update
        update_method(crud_type)
      end
    end
  end
  def self.update_method(crud_type)
    define_method(crud_type) do |sObjectType, obj, hParams|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, obj, hParams)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  def self.query_method(crud_type)
    define_method(crud_type) do |sObjectType, sCondition, hParams|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, hParams, sCondition)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  def self.base_method(crud_type)
    define_method(crud_type) do |sObjectType, p1|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, p1)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  # Define the hpcloud controller handlers
  # def_cruds :create, :delete, :get, :query, :update, :refresh
  def_cruds :refresh

  def connect(sObjectType, hParams)
    case sObjectType
    when :services
      Fog::HP.authenticate_v2(hParams[:hdata], hParams[:excon_opts])
    when :compute_connection
      Fog::Compute.new hParams[:hdata].merge(:provider => :hp, :version => 'v2')
    when :network_connection
      Fog::HP::Network.new(hParams[:hdata])
    else
      controller_error "'%s' is not a valid object for 'connect'", sObjectType
    end
  end

  # rubocop: disable MethodLength, CyclomaticComplexity, AbcSize

  # Create controller for Hpcloud
  def create(sObjectType, hParams)
    case sObjectType
    when :public_ip
      required?(hParams, :compute_connection)
      required?(hParams, :server)
      HPCompute.server_assign_address(hParams[:compute_connection],
                                      hParams[:server])
    when :server
      required?(hParams, :compute_connection)
      required?(hParams, :image)
      required?(hParams, :network)
      required?(hParams, :flavor)
      required?(hParams, :keypairs)
      required?(hParams, :security_groups)
      required?(hParams, :server_name)

      options = {
        :name => hParams[:server_name],
        :flavor_id => hParams[:flavor].id,
        :image_id => hParams[:image].id,
        :key_name => hParams[:keypairs].name,
        :security_groups => [hParams[:security_groups].name],
        :networks => [hParams[:network].id]
      }

      HPCompute.create_server(hParams[:compute_connection], options,
                              hParams[:user_data], hParams[:meta_data])
    when :image
      required?(hParams, :compute_connection)
      required?(hParams, 'server#image_name')

      HPCompute.get_image(hParams[:compute_connection],
                          hParams['server#image_name'])
    when :network
      required?(hParams, :network_connection)
      required?(hParams, :network_name)

      HPNetwork.create_network(hParams[:network_connection],
                               hParams[:network_name])
    when :subnetwork
      required?(hParams, :network_connection)
      required?(hParams, :network)
      required?(hParams, :subnetwork_name)

      HPNetwork.create_subnetwork(hParams[:network_connection],
                                  hParams[:network],
                                  hParams[:subnetwork_name])
    when :security_groups
      required?(hParams, :network_connection)
      required?(hParams, :security_group)

      HPSecurityGroups.create_sg(hParams[:network_connection],
                                 hParams[:security_group], hParams[:sg_desc])
    when :keypairs
      required?(hParams, :compute_connection)
      required?(hParams, 'credentials#keypair_name')
      required?(hParams, :public_key)

      HPKeyPairs.create_keypair(hParams[:compute_connection],
                                hParams['credentials#keypair_name'],
                                hParams[:public_key])
    when :router
      required?(hParams, :network_connection)
      required?(hParams, :router_name)

      # Forcelly used admin_status_up to true.
      hParams[:hdata] = hParams[:hdata].merge(:admin_state_up => true)

      HPNetwork.create_router(hParams[:network_connection], hParams[:hdata])
    when :rule
      required?(hParams, :network_connection)
      required?(hParams, :security_groups)
      HPSecurityGroups.create_rule(hParams[:network_connection],
                                   hParams[:hdata])
    when :router_interface
      required?(hParams, :router)
      required?(hParams, :subnetwork)
      HPNetwork.add_interface(hParams[:router], hParams[:subnetwork])
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end

  # rubocop: enable CyclomaticComplexity, MethodLength

  def delete(sObjectType, hParams)
    case sObjectType
    when :network
      HPNetwork.delete_network(hParams[:network_connection],
                               hParams[:network])
    when :rule
      HPSecurityGroups.delete_rule(hParams[:network_connection],
                                   hParams[:id])
      obj = hParams[:network_connection]
      obj.security_group_rules.get(hParams[:id]).destroy
    when :server
      required?(hParams, :compute_connection)
      required?(hParams, :server)
      HPCompute.delete_server(hParams[:compute_connection],
                              hParams[:server])
    end
  end
  # rubocop: disable CyclomaticComplexity,
  def get(sObjectType, sUniqId, hParams)
    case sObjectType
    when :server_log
      required?(hParams, :server)

      hParams[:server].console_output(sUniqId)
    when :server
      required?(hParams, :compute_connection)
      HPCompute.get_server(hParams[:compute_connection], sUniqId)
    when :image
      required?(hParams, :compute_connection)
      HPCompute.get_image(hParams[:compute_connection], sUniqId)
    when :network
      required?(hParams, :network_connection)
      HPNetwork.get_network(hParams[:network_connection], sUniqId)
    when :keypairs
      required?(hParams, :compute_connection)
      HPKeyPairs.get_keypair(hParams[:compute_connection], sUniqId)
    when :public_ip
      required?(hParams, :compute_connection)
      required?(hParams, :server)
      HPCompute.get_server_assigned_address(hParams[:compute_connection],
                                            sUniqId)
    else
      forjError "'%s' is not a valid object for 'get'", sObjectType
    end
  end
  # rubocop: enable CyclomaticComplexity

  def query_each(oFogObject)
    case oFogObject.class.to_s
    when 'Fog::HP::Network::Networks'
      oFogObject.each { |value| yield(value) }
    else
      controller_error "'%s' is not a valid list for 'each'",
                       oFogObject.class
    end
  end

  def get_attr(oControlerObject, key)
    if oControlerObject.is_a?(Excon::Response)
      oControlerObject.data.rh_get(:body, key)
    else
      _get_instance_attr(oControlerObject, key)
    end
  rescue => e
    controller_error "Unable to map '%s'. %s", key, e.message
  end

  def _server_metadata_get(oControlerObject, key)
    return [false, nil] unless key == :metadata
    ret = {}
    oControlerObject.metadata.each do |m|
      k = m.attributes[:key]
      v = m.attributes[:value]
      ret[k] = v
    end
    [true, ret]
  end

  def _get_instance_attr(oControlerObject, key)
    found, ret = _server_metadata_get(oControlerObject, key[0])
    found, ret = _get_from(oControlerObject, key[0]) unless found

    unless found
      Lorj.debug(4, "Unable to get '%s' from '%s'. Attribute inexistent.",
                 key[0], oControlerObject.class)
      return nil
    end

    return ret if key.length == 1 || !ret.is_a?(Hash)
    ret.rh_get(key[1..-1])
  end

  def set_attr(oControlerObject, key, value)
    controller_class = oControlerObject.class

    controller_error "No set feature for '%s'",
                     controller_class if oControlerObject.is_a?(Excon::Response)

    attributes = oControlerObject.attributes
    def_attributes = oControlerObject.class.attributes
    controller_error "attribute '%s' is unknown in '%s'. Valid one are : '%s'",
                     key[0], oControlerObject.class,
                     def_attributes unless def_attributes.include?(key[0])
    attributes.rh_set(value, key)
  rescue => e
    controller_error "Unable to map '%s' on '%s'\n%s",
                     key, sObjectType, e.message
  end

  def update(sObjectType, oObject, _hParams)
    case sObjectType
    when :router
      controller_error 'Object to update is nil' if oObject.nil?

      HPNetwork.update_router(oObject[:object])
    else
      controller_error "'%s' is not a valid list for 'update'",
                       oFogObject.class
    end
  end

  # This function requires to return an Array of values or nil.
  def get_services(sObjectType, oParams)
    case sObjectType
    when :services
      # oParams[sObjectType] will provide the controller object.
      # This one can be interpreted only by controller code,
      # except if controller declares how to map with this object.
      # Processes can deal only process mapped data.
      # Currently there is no services process function. No need to map.
      services = oParams[:services]
      if !oParams[:list_services].is_a?(Array)
        service_to_find = [oParams[:list_services]]
      else
        service_to_find = oParams[:list_services]
      end
      # Search for service. Ex: Can be :Networking or network. I currently do
      # not know why...
      search_services = services.rh_get(:service_catalog)
      service = nil
      service_to_find.each do |sServiceElem|
        if search_services.key?(sServiceElem)
          service = sServiceElem
          break
        end
      end

      controller_error 'Unable to find services %s',
                       service_to_find if service.nil?
      result = services.rh_get(:service_catalog, service).keys
      result.delete('name')
      result.each_index do |iIndex|
        result[iIndex] = result[iIndex].to_s if result[iIndex].is_a?(Symbol)
      end
      return result
    else
      controller_error "'%s' is not a valid object for 'get_services'",
                       sObjectType
    end
  end
end

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
require 'fog'
require 'uri'

hpcloud_path = File.expand_path(File.dirname(__FILE__))

require File.join(hpcloud_path, 'openstack_query.rb')
require File.join(hpcloud_path, 'openstack_get.rb')
require File.join(hpcloud_path, 'openstack_delete.rb')
require File.join(hpcloud_path, 'openstack_create.rb')
require File.join(hpcloud_path, 'openstack_update.rb')

# Defines Meta Openstack object
class Openstack
  process_default :use_controller => true

  define_obj :services
  # Define Data used by service

  obj_needs :data, :account_id,  :mapping => :openstack_username
  obj_needs :data, :account_key, :mapping => :openstack_api_key,
                                 :decrypt => true
  obj_needs :data, :auth_uri,    :mapping => :openstack_auth_uri
  obj_needs :data, :tenant,      :mapping => :openstack_tenant
  obj_needs :data, ':excon_opts/:connect_timeout', :default_value => 30
  obj_needs :data, ':excon_opts/:read_timeout',    :default_value => 240
  obj_needs :data, ':excon_opts/:write_timeout',   :default_value => 240

  define_obj :compute_connection
  # Defines Data used by compute.

  obj_needs :data, :account_id,  :mapping => :openstack_username
  obj_needs :data, :account_key, :mapping => :openstack_api_key,
                                 :decrypt => true
  obj_needs :data, :auth_uri,    :mapping => :openstack_auth_url
  obj_needs :data, :tenant,      :mapping => :openstack_tenant
  obj_needs :data, :compute,     :mapping => :openstack_region

  define_obj :network_connection
  obj_needs :data, :account_id,  :mapping => :openstack_username
  obj_needs :data, :account_key, :mapping => :openstack_api_key,
                                 :decrypt => true
  obj_needs :data, :auth_uri,    :mapping => :openstack_auth_url
  obj_needs :data, :tenant,      :mapping => :openstack_tenant
  obj_needs :data, :network,     :mapping => :openstack_region

  # Openstack tenants object
  define_obj(:tenants, :create_e => :openstack_get_tenant)
  obj_needs :CloudObject, :compute_connection
  obj_needs :data, :tenant

  # Openstack Network
  define_obj :network
  def_hdata :network_name, :mapping => :name
  def_attr_mapping :external, :router_external

  define_obj :keypairs

  undefine_attribute :id    # Do not return any predefined ID

  define_obj :server_log

  # Excon::Response object type
  def_attr_mapping :output, 'output'

  define_obj :security_groups
  # Added tenant data to add in queries.
  obj_needs :CloudObject, :tenants

  define_obj :rule
  obj_needs :data, :dir,        :mapping => :direction
  attr_value_mapping :IN,  'ingress'
  attr_value_mapping :OUT, 'egress'

  obj_needs :data, :proto,      :mapping => :protocol
  obj_needs :data, :port_min,   :mapping => :port_range_min
  obj_needs :data, :port_max,   :mapping => :port_range_max
  obj_needs :data, :addr_map,   :mapping => :remote_ip_prefix
  obj_needs :data, :sg_id,      :mapping => :security_group_id

  def_attr_mapping :dir,      :direction
  def_attr_mapping :proto,    :protocol
  def_attr_mapping :port_min, :port_range_min
  def_attr_mapping :port_max, :port_range_max
  def_attr_mapping :addr_map, :remote_ip_prefix
  def_attr_mapping :sg_id,    :security_group_id

  define_data(:account_id,
              :account => true,
              :desc => 'Openstack Username',
              :validate => /^.+/
             )

  define_data(:account_key,
              :account => true,
              :desc => 'Openstack Password',
              :validate => /^.+/
             )
  define_data(:auth_uri,
              :account => true,
              :explanation => "The authentication service is identified as '"\
                "identity' under your horizon UI - Project/Compute then "\
                'Access & security.',
              :desc => 'Openstack Authentication service URL. '\
                'Ex: https://mycloud:5000/v2.0/tokens',
              :validate => %r{^http(s)?:\/\/.*\/tokens$}
             )
  define_data(:tenant,
              :account => true,
              :explanation => 'The Project name is shown from your horizon UI'\
                ', on top left, close to the logo',
              :desc => 'Openstack Tenant Name',
              :validate => /^.+/
             )

  define_data(:compute,
              :account => true,
              :default_value => '<%= config[:network] %>',
              :explanation => 'Depending on your installation, you may need to'\
                ' provide a Region name. This information is shown under your '\
                'horizon UI - close right to the project name (top left).'\
                "\nYou can also get it from Project-Compute-Access & Security-"\
                'API, then download the Openstack RC file. The Region name is '\
                'set as OS_REGION_NAME.'\
                "\nIf there is no region shown, you can ignore it.",
              :desc => 'Openstack Compute Region (Ex: RegionOne)',
              :depends_on => [:account_id, :account_key, :auth_uri, :tenant],
              :list_values => {
                :query_type => :controller_call,
                :object => :services,
                :query_call => :get_services,
                :query_params => { :list_services => [:Compute, :compute] },
                :validate => :list_strict
              }
             )

  define_data(:network,
              :account => true,
              :default_value => '<%= config[:compute] %>',
              :desc => 'Openstack Network Region (Ex: RegionOne)',
              :explanation => 'Depending on your installation, you may need to'\
                ' provide a Region name. This information is shown under your '\
                'horizon UI - close right to the project name (top left).'\
                "\nYou can also get it from Project-Compute-Access & Security-"\
                'API, then download the Openstack RC file. The Region name is '\
                'set as OS_REGION_NAME.'\
                "\nIf there is no region shown, you can ignore it.",
              :depends_on => [:account_id, :account_key, :auth_uri, :tenant],
              :list_values => {
                :query_type => :controller_call,
                :object => :services,
                :query_call => :get_services,
                :query_params => { :list_services => [:Networking, :network] },
                :validate => :list_strict
              }
             )

  define_obj :server
  def_attr_mapping :status, :state
  attr_value_mapping :create, 'BUILD'
  attr_value_mapping :boot,   :boot
  attr_value_mapping :active, 'ACTIVE'
  attr_value_mapping :error, 'ERROR'

  def_attr_mapping :private_ip_address, :accessIPv4
  def_attr_mapping :public_ip_address, :accessIPv4
  def_attr_mapping :image_id, [:image, 'id']

  define_obj :router
  obj_needs_optional
  obj_needs :data, :router_name, :mapping => :name

  # The FORJ gateway_network_id is extracted
  # from Fog::HP::Network::Router[:external_gateway_info][:network_id]

  obj_needs :data,
            :external_gateway_id,
            :mapping => [:external_gateway_info, 'network_id']

  def_attr_mapping :gateway_network_id, [:external_gateway_info, 'network_id']

  # Port attributes used specifically by openstack fog API.
  define_obj :port
  def_attribute :device_owner
  def_attribute :network_id

  define_obj :public_ip
  def_attr_mapping :server_id, :instance_id
  def_attr_mapping :public_ip, :ip

  define_obj :image
  def_attr_mapping :image_name, :name
end

# Following class describe how FORJ should handle Openstack Cloud objects.
class OpenstackController
  def self.def_cruds(*crud_types)
    crud_types.each do |crud_type|
      case crud_type
      when :create, :delete
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
    define_method(crud_type) do |sObjectType, hParams|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, hParams)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  # Define the Openstack controller handlers
  def_cruds :create, :delete, :get, :query, :update

  def connect(sObjectType, hParams)
    case sObjectType
    when :services
      # Fog use URI type for auth uri: URI.parse(:auth_uri)
      # Convert openstack_auth_uri to type URI
      hParams[:hdata][:openstack_auth_uri] =
          URI.parse(hParams[:hdata][:openstack_auth_uri])
      retrieve_result =
          Fog::OpenStack.retrieve_tokens_v2(hParams[:hdata],
                                            hParams[:excon_opts])
      creds = format_retrieve_result(retrieve_result)
      return creds
    when :compute_connection
      Fog::Compute.new(
        hParams[:hdata].merge(:provider => :openstack)
      )
    when :network_connection
      Fog::Network::OpenStack.new(hParams[:hdata])
    else
      controller_error "'%s' is not a valid object for 'connect'", sObjectType
    end
  end

  def set_attr(oControlerObject, key, value)
    if oControlerObject.is_a?(Excon::Response)
      controller_error "No set feature for '%s'", oControlerObject.class
    end

    attributes = oControlerObject.attributes

    controller_error "attribute '%s' is unknown in '%s'. Valid one are : '%s'",
                     key[0],
                     oControlerObject.class,
                     oControlerObject.class.attributes unless
                     oControlerObject.class.attributes.include?(key[0])

    attributes.rh_set(value, key)
  rescue => e
    controller_error "Unable to map '%s' on '%s'. %s",
                     key, oControlerObject, e.message
  end

  def get_attr(oControlerObject, key)
    if oControlerObject.is_a?(Excon::Response)
      oControlerObject.data.rh_get(:body, key)
    else
      attributes = oControlerObject.attributes
      controller_error "attribute '%s' is unknown in '%s'."\
                       " Valid one are : '%s'",
                       key[0],
                       oControlerObject.class,
                       oControlerObject.class.attributes unless
                       oControlerObject.class.attributes.include?(key[0])
      return attributes.rh_get(key) if attributes.rh_exist?(key)
      _get_instance_attr(oControlerObject, key)
    end
  rescue => e
    controller_error "==>Unable to map '%s'. %s", key, e.message
  end

  def _get_instance_attr(oControlerObject, key)
    return nil if oControlerObject.send(key[0]).nil?
    return oControlerObject.send(key[0]) if key.length == 1
    oControlerObject.send(key[0]).rh_get(key[1..-1])
  end
end

# Following class describe how FORJ should handle Openstack Cloud objects.
class OpenstackController
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

  def format_retrieve_result(retrieve_result)
    {
      :auth_token => retrieve_result['access']['token']['id'],
      :expires => retrieve_result['access']['token']['expires'],
      :service_catalog =>
          get_service_catalog(retrieve_result['access']['serviceCatalog']),
      :endpoint_url => nil,
      :cdn_endpoint_url => nil
    }
  end

  def get_service_catalog(body)
    fail 'Unable to parse service catalog.' unless body
    service_catalog = {}
    body.each do |s|
      type = s['type']
      next if type.nil?
      type = type.to_sym
      next if s['endpoints'].nil?
      service_catalog[type] = {}
      service_catalog[type]['name'] = s['name']
      service_catalog = parse_service_catalog_endpoint(s, type, service_catalog)
    end
    service_catalog
  end

  def parse_service_catalog_endpoint(s, type, service_catalog)
    s['endpoints'].each do |ep|
      next if ep['region'].nil?
      next if ep['publicURL'].nil?
      next if ep['publicURL'].empty?
      service_catalog[type][ep['region'].to_sym] = ep['publicURL']
    end
    service_catalog
  end
end

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

# Defines Meta HPCloud object
class Hpcloud
  define_obj :services
  obj_needs :data, 'credentials#account_id',      :mapping => :hp_access_key
  obj_needs :data, 'credentials#account_key',     :mapping => :hp_secret_key
  obj_needs :data, 'credentials#auth_uri',        :mapping => :hp_auth_uri
  obj_needs :data, 'credentials#tenant',          :mapping => :hp_tenant_id
  obj_needs :data, ':excon_opts/:connect_timeout', :default_value => 30
  obj_needs :data, ':excon_opts/:read_timeout',    :default_value => 240
  obj_needs :data, ':excon_opts/:write_timeout',   :default_value => 240

  # Defines Object structure and function stored on the Hpcloud class object.
  # Compute Object
  define_obj :compute_connection
  # Defines Data used by compute.

  obj_needs :data, 'credentials#account_id',  :mapping => :hp_access_key
  obj_needs :data, 'credentials#account_key', :mapping => :hp_secret_key
  obj_needs :data, 'credentials#auth_uri',    :mapping => :hp_auth_uri
  obj_needs :data, 'credentials#tenant',      :mapping => :hp_tenant_id
  obj_needs :data, 'services#compute',        :mapping => :hp_avl_zone

  define_obj :network_connection
  obj_needs :data, 'credentials#account_id',  :mapping => :hp_access_key
  obj_needs :data, 'credentials#account_key', :mapping => :hp_secret_key
  obj_needs :data, 'credentials#auth_uri',    :mapping => :hp_auth_uri
  obj_needs :data, 'credentials#tenant',      :mapping => :hp_tenant_id
  obj_needs :data, 'services#network',        :mapping => :hp_avl_zone

  # Forj predefine following query mapping, used by ForjProcess
  # id => id, name => name
  # If we need to add another mapping, add
  # query_mapping :id => :MyID
  # If the query is not push through and Hash object, the Provider
  # will needs to create his own mapping function.
  define_obj :network
  def_attr_mapping :external, :router_external

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

  define_obj :keypairs

  undefine_attribute :id    # Do not return any predefined ID

  # ************************************ Router Object
  define_obj :router

  obj_needs_optional
  obj_needs :data,   :router_name,         :mapping => :name
  # The FORJ gateway_network_id is extracted from
  # Fog::HP::Network::Router[:external_gateway_info][:network_id]
  obj_needs :data,   :external_gateway_id, :mapping => [:external_gateway_info,
                                                        'network_id']

  def_attr_mapping :gateway_network_id, [:external_gateway_info, 'network_id']

  # ************************************ SERVER Object
  define_obj :server

  def_attr_mapping :private_ip_addresses,
                   [:addresses, '{/.*/}',
                    '<%= data["OS-EXT-IPS:type"] == "fixed" %>|addr']
  def_attr_mapping :public_ip_address,
                   [:addresses, '{/.*/}',
                    '<%= data["OS-EXT-IPS:type"] == "floating" %>|addr']
  def_attr_mapping :priv_ip_addresses,
                   [:addresses, '{/.*/0}',
                    '<%= data["OS-EXT-IPS:type"] == "fixed" %>|addr']
  def_attr_mapping :pub_ip_addresses,
                   [:addresses, '{/.*/0}',
                    '<%= data["OS-EXT-IPS:type"] == "floating" %>|addr']
  def_attr_mapping :meta_data, :metadata

  def_attr_mapping :status, :state
  attr_value_mapping :create,   'BUILD'
  attr_value_mapping :boot,     :boot
  attr_value_mapping :active,   'ACTIVE'
  attr_value_mapping :error,    'ERROR'
  attr_value_mapping :shutdown, 'SHUTOFF'
  attr_value_mapping :deleted,  'DELETED'

  # ************************************ SERVER log Object
  define_obj :server_log

  # Excon::Response object type
  def_attr_mapping :output,  'output'

  # ************************************* Public IP Object
  define_obj :public_ip
  def_attr_mapping :server_id, :instance_id
  def_attr_mapping :public_ip, :ip

  # defines setup Cloud data (:account => true for setup)
  define_data('credentials#account_id',
              :account => true,
              :desc => 'HPCloud Access Key (From horizon, user drop down, '\
                       'manage keys)',
              :validate => /^[A-Z0-9]*$/
             )
  define_data('credentials#account_key',
              :account => true,
              :desc => 'HPCloud secret Key (From horizon, user drop down, '\
                       'manage keys)',
              :encrypted => false,
              :validate => /^.+/
             )
  define_data('credentials#auth_uri',
              :account => true,
              :desc => 'HPCloud Authentication service URL (default is HP '\
                       'Public cloud)',
              :validate => %r{^http(s)?://.*$},
              :default_value => 'https://region-a.geo-1.identity.hpcloudsvc'\
                                '.com:35357/v2.0/'
             )
  define_data('credentials#tenant',
              :account => true,
              :desc => 'HPCloud Tenant ID (from horizon, identity, projecs,'\
                       ' Project ID)',
              :validate => /^[0-9]+$/
             )

  define_data('services#compute',
              :account => true,
              :desc => 'HPCloud Compute service zone (Ex: region-a.geo-1)',
              :list_values => {
                :query_type => :controller_call,
                :object => :services,
                :query_call => :get_services,
                :query_params => { :list_services => [:Compute, :compute] },
                :validate => :list_strict
              }
             )

  define_data('services#network',
              :account => true,
              :desc => 'HPCloud Network service zone (Ex: region-a.geo-1)',
              :list_values => {
                :query_type => :controller_call,
                :object => :services,
                :query_call => :get_services,
                :query_params => { :list_services => [:Networking, :network] },
                :validate => :list_strict
              }
             )

  data_value_mapping 'xsmall', 'standard.xsmall'
  data_value_mapping 'small',  'standard.small'
  data_value_mapping 'medium', 'standard.medium'
  data_value_mapping 'large',  'standard.large'
  data_value_mapping 'xlarge', 'standard.xlarge'
end

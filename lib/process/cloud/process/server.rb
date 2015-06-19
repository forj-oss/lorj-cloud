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
# Server management
# ---------------------------------------------------------------------------
class CloudProcess
  # Process Handler functions
  def forj_get_or_create_server(sCloudObj, hParams)
    server_name = hParams[:server_name]
    PrcLib.state("Searching for server '%s'", server_name)

    config[:search_for] = server_name
    servers = forj_query_server(sCloudObj, { :name => server_name }, hParams)
    if servers.length > 0
      # Get server details
      forj_get_server(sCloudObj, servers[0][:attrs][:id], hParams)
    else
      create_server(sCloudObj, hParams)
    end
  end

  def forj_delete_server(sCloudObj, hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_delete(sCloudObj)
      PrcLib.info('Server %s was destroyed ', hParams[:server][:name])
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  def forj_query_server(sCloudObj, sQuery, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      query_single(sCloudObj, sQuery, config[:search_for])
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  def forj_get_server(sCloudObj, sId, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sId)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end
end

# SERVER Object
# Identify the server to use/build on the network/...
class Lorj::BaseDefinition
  define_obj(:server,

             :create_e => :forj_get_or_create_server,
             :query_e => :forj_query_server,
             :get_e => :forj_get_server,
             #         :update_e   => :forj_update_server,
             :delete_e => :forj_delete_server
            )

  obj_needs :CloudObject,  :compute_connection
  obj_needs :CloudObject,  :flavor,              :for => [:create_e]
  obj_needs :CloudObject,  :network,             :for => [:create_e]
  obj_needs :CloudObject,  :security_groups,     :for => [:create_e]
  obj_needs :CloudObject,  :keypairs,            :for => [:create_e]
  obj_needs :CloudObject,  :image,               :for => [:create_e]
  obj_needs :data,         :server_name,         :for => [:create_e]

  obj_needs_optional
  obj_needs :data,         :user_data,           :for => [:create_e]
  obj_needs :data,         :meta_data,           :for => [:create_e]

  def_attribute :status
  predefine_data_value :create,   :desc => 'Server is creating.'
  predefine_data_value :boot,     :desc => 'Server is booting.'
  predefine_data_value :active,   :desc => 'Server is started.'
  predefine_data_value :error,    :desc => 'Server is in error.'
  predefine_data_value :shutdown, :desc => 'Server is down.'
  # The private addresses attribute should be composed by
  # network_name:
  # - IP addresses
  # The controller must return at least those structured data.
  def_attribute :private_ip_addresses
  def_attribute :public_ip_address

  def_attribute :image_id
  def_attribute :key_name
  def_attribute :meta_data
end

# Internal Process function
class CloudProcess
  def create_server(sCloudObj, hParams)
    name = hParams[:server_name]
    begin
      PrcLib.info('boot: meta-data provided.') if hParams[:meta_data]
      PrcLib.info('boot: user-data provided.') if hParams[:user_data]
      PrcLib.state('creating server %s', name)
      server = controller_create(sCloudObj)
      PrcLib.info("%s '%s' created.", sCloudObj, name)
    rescue => e
      PrcLib.fatal(1, "Unable to create server '%s'", name, e)
    end
    server
  end

  def forj_get_server_log(sCloudObj, sId, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sId)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end
end

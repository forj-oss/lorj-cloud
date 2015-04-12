#!/usr/bin/env ruby
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

# Connection process code
class CloudProcess
  def connect(sCloudObj, hParams)
    ssl_error_obj = SSLErrorMgt.new # Retry object
    PrcLib.debug("%s:%s Connecting to '%s' "\
                 "- Project '%s'",
                 self.class, sCloudObj, config[:provider], hParams[:tenant])
    begin
      controller_connect(sCloudObj)
   rescue => e
     retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)

     PrcLib.error('%s:%s: Unable to connect.\n%s',
                  self.class, sCloudObj, e.message)
     nil
    end
  end
end

# Define services model
class Lorj::BaseDefinition
  # predefined list of objects.
  # Links between objects is not predefined. To do it, use needs declaration
  # in your provider class.

  # object to get list of services
  # Defines Process handler to call
  define_obj(:services,

             :create_e => :connect
            )
  obj_needs :data, :auth_uri
  obj_needs :data, :account_id
  obj_needs :data, :account_key
  obj_needs :data, :tenant

  undefine_attribute :id    # Do not return any predefined ID
  undefine_attribute :name  # Do not return any predefined NAME
end

# compute_connection
class Lorj::BaseDefinition
  define_obj(:compute_connection,

             :create_e => :connect # Will call ForjProcess connect
            )
  obj_needs :data, :account_id
  obj_needs :data, :account_key
  obj_needs :data, :auth_uri
  obj_needs :data, :tenant
  obj_needs :data, :compute

  undefine_attribute :id    # Do not return any predefined ID
  undefine_attribute :name  # Do not return any predefined NAME
end

# network_connection
class Lorj::BaseDefinition
  define_obj(:network_connection,

             :create_e => :connect
            )
  obj_needs :data, :account_id
  obj_needs :data, :account_key
  obj_needs :data, :auth_uri
  obj_needs :data, :tenant
  obj_needs :data, :network

  undefine_attribute :id    # Do not return any predefined ID
  undefine_attribute :name  # Do not return any predefined NAME
end

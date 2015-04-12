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

# SecurityGroups rules management
class CloudProcess
  # Process Delete handler
  def forj_delete_rule(sCloudObj, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_delete(sCloudObj)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  # Process Query handler
  def forj_query_rule(sCloudObj, sQuery, hParams)
    rule = format('%s %s:%s - %s to %s', hParams[:dir], hParams[:rule_proto],
                  hParams[:port_min], hParams[:port_max],
                  hParams[:addr_map])
    PrcLib.state("Searching for rule '%s'", rule)
    ssl_error_obj = SSLErrorMgt.new
    begin
      info = {
        :items => [:dir, :proto, :port_min, :port_max, :addr_map],
        :items_form => '%s %s:%s - %s to %s'
      }
      #  list = controller_query(sCloudObj, sQuery)
      #  query_single(sCloudObj, list, sQuery, rule, info)
      query_single(sCloudObj, sQuery, rule, info)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  # Process Create handler
  def forj_get_or_create_rule(sCloudObj, hParams)
    query = {
      :dir => hParams[:dir],
      :proto => hParams[:proto],
      :port_min => hParams[:port_min],
      :port_max => hParams[:port_max],
      :addr_map => hParams[:addr_map],
      :sg_id => hParams[:sg_id]
    }
    rules = forj_query_rule(sCloudObj, query, hParams)
    if rules.length == 0
      create_rule(sCloudObj, hParams)
    else
      rules[0]
    end
  end
end

# Security group rules Object
# Identify Rules attached to the security group
class Lorj::BaseDefinition
  define_obj(:rule,

             :create_e => :forj_get_or_create_rule,
             :query_e => :forj_query_rule
            #         :delete_e   => :forj_delete_rule
            )

  undefine_attribute :name  # Do not return any predefined name attribute

  obj_needs :CloudObject, :network_connection
  obj_needs :CloudObject, :security_groups, :for => [:create_e]
  obj_needs :data,        :sg_id, :for => [:create_e],
                                  :extract_from => [:security_groups,
                                                    :attrs, :id]

  obj_needs :data,        :dir,                 :for => [:create_e]
  predefine_data_value :IN,   :desc => 'Input NAT/firewall rule map type'
  predefine_data_value :OUT,  :desc => 'Output NAT/firewall rule map type'

  obj_needs :data,        :proto,               :for => [:create_e]
  obj_needs :data,        :port_min,            :for => [:create_e]
  obj_needs :data,        :port_max,            :for => [:create_e]
  obj_needs :data,        :addr_map,            :for => [:create_e]
end

# SecurityGroups rules management
class CloudProcess
  # Rules internal #
  #----------------#
  def create_rule(sCloudObj, hParams)
    rule_msg = format('%s %s:%s - %s to %s',
                      hParams[:dir], hParams[:rule_proto],
                      hParams[:port_min], hParams[:port_max],
                      hParams[:addr_map])
    PrcLib.state("Creating rule '%s'", rule_msg)
    ssl_error_obj = SSLErrorMgt.new
    begin
      rule = controller_create(sCloudObj)
      PrcLib.info("Rule '%s' created.", rule_msg)
    rescue StandardError => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
      PrcLib.error 'error creating the rule "%s"', rule_msg
    end
    rule
  end
end

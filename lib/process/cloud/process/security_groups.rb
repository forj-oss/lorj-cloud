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

# SecurityGroups management
class CloudProcess
  # Process Create handler
  def forj_get_or_create_sg(sCloudObj, hParams)
    sg_name = hParams[:security_group]
    PrcLib.state("Searching for security group '%s'", sg_name)

    security_group = forj_query_sg(sCloudObj, { :name => sg_name }, hParams)
    security_group = create_security_group(sCloudObj,
                                           hParams) unless security_group
    register(security_group)

    PrcLib.info('Configuring Security Group \'%s\'', sg_name)
    ports = config.get(:ports)

    ports.each do |port|
      port = port.to_s if port.class != String
      if !(/^\d+(-\d+)?$/ =~ port)
        PrcLib.error("Port '%s' is not valid. Must be <Port> or "\
                     '<PortMin>-<PortMax>', port)
      else
        port_found_match = /^(\d+)(-(\d+))?$/.match(port)
        portmin = port_found_match[1]
        portmax = (port_found_match[3]) ? (port_found_match[3]) : (portmin)
        # Need to set runtime data to get or if missing
        # create the required rule.
        params = {}
        params[:dir]        = :IN
        params[:proto] = 'tcp'
        params[:port_min]   = portmin.to_i
        params[:port_max]   = portmax.to_i
        params[:addr_map]   = '0.0.0.0/0'

        # object.Create(:rule)
        process_create(:rule, params)
      end
    end
    security_group
  end

  # Process Delete handler
  def forj_delete_sg(sCloudObj, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_delete(sCloudObj)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  # Process Query handler
  def forj_query_sg(sCloudObj, sQuery, hParams)
    ssl_error_obj = SSLErrorMgt.new

    begin
      sgroups = controller_query(sCloudObj, sQuery)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
      PrcLib.fatal(1, 'Unable to get list of security groups.', e)
    end
    case sgroups.length
    when 0
      PrcLib.info("No security group '%s' found",
                  hParams[:security_group])
      nil
    when 1
      PrcLib.info("Found security group '%s'", sgroups[0, :name])
      sgroups[0]
    end
  end
end

# ************************************ Security groups Object
# Identify security_groups
class Lorj::BaseDefinition
  define_obj(:security_groups,
             :create_e => :forj_get_or_create_sg,
             :query_e => :forj_query_sg,
             :delete_e => :forj_delete_sg
            )

  obj_needs :CloudObject,  :network_connection
  obj_needs :data,         :security_group,      :for => [:create_e]
  obj_needs_optional
  obj_needs :data,         :sg_desc,             :for => [:create_e]
end

# SecurityGroups Process internal functions #
class CloudProcess
  def create_security_group(sCloudObj, hParams)
    PrcLib.state("Creating security group '%s'", hParams[:security_group])
    begin
      sg = controller_create(sCloudObj)
      PrcLib.info("Security group '%s' created.", sg[:name])
    rescue => e
      PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
    sg
  end
end

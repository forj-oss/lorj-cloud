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

# ---------------------------------------------------------------------------
# flavor management
# ---------------------------------------------------------------------------
class CloudProcess
  # Depending on clouds/rights, we can create flavor or not.
  # Usually, flavor records already exists, and the controller may map them
  # CloudProcess predefines some values. Consult CloudProcess.rb for details
  def forj_get_or_create_flavor(sCloudObj, hParams)
    flavor_name = hParams[:flavor_name]
    PrcLib.state("Searching for flavor '%s'", flavor_name)

    flavors = query_flavor(sCloudObj, { :name => flavor_name }, hParams)
    if flavors.length == 0
      if !hParams[:create]
        PrcLib.error("Unable to create %s '%s'. Creation is not "\
                     'supported.', sCloudObj, flavor_name)
        ForjLib::Data.new.set(nil, sCloudObj)
      else
        create_flavor(sCloudObj, hParams)
      end
    else
      flavors[0]
    end
  end

  # Should return 1 or 0 flavor.
  def query_flavor(sCloudObj, sQuery, hParams)
    flavor_name = hParams[:flavor_name]
    #  list = forj_query_flavor(sCloudObj, sQuery, hParams)
    #  query_single(sCloudObj, list, sQuery, flavor_name)
    query_single(sCloudObj, sQuery, flavor_name)
  end

  # Should return 1 or 0 flavor.
  def forj_query_flavor(sCloudObj, sQuery, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      list = controller_query(sCloudObj, sQuery)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
    list
  end
end

# Flavor Object
# Identify flavor
class Lorj::BaseDefinition # rubocop: disable ClassAndModuleChildren
  define_obj(:flavor,

             :create_e => :forj_get_or_create_flavor,
             :query_e => :forj_query_flavor
            #         :get_e      => :forj_get_flavor,
            #         :update_e   => :forj_update_flavor,
            #         :delete_e   => :forj_delete_flavor
            )

  obj_needs :CloudObject,  :compute_connection
  obj_needs :data,         :flavor_name,         :for => [:create_e]
  # Cloud provider will need to map to one of those predefined flavors.
  # limitation values may match exactly or at least ensure those limitation
  # are under provider limitation
  # ie, at least the CloudProcess limitation can less than the
  # Cloud provider defines.
  # CloudProcess EHD = 160, then Provider EHD = 200 is ok
  # but Provider EHD = 150 is not ok.
  predefine_data_value('tiny',    :desc => 'VCU: 1,  RAM:512M, HD:1G,   '\
                                           'EHD: 0G,   Swap: 0G')
  predefine_data_value('xsmall',  :desc => 'VCU: 1,  RAM:1G,   HD:10G,  '\
                                           'EHD: 10G,  Swap: 0G')
  predefine_data_value('small',   :desc => 'VCU: 2,  RAM:2G,   HD:30G,  '\
                                           'EHD: 10G,  Swap: 0G')
  predefine_data_value('medium',  :desc => 'VCU: 2,  RAM:4G,   HD:30G,  '\
                                           'EHD: 50G,  Swap: 0G')
  predefine_data_value('large',   :desc => 'VCU: 4,  RAM:8G,   HD:30G,  '\
                                           'EHD: 100G, Swap: 0G')
  predefine_data_value('xlarge',  :desc => 'VCU: 8,  RAM:16G,  HD:30G,  '\
                                           'EHD: 200G, Swap: 0G')
end

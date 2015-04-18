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

# Specific openstack process added to the application process.
class OpenstackProcess
  def openstack_get_tenant(sObjectType, hParams)
    tenant_name = hParams[:tenant]
    query = { :name => tenant_name }
    PrcLib.state("searching for tenant '%s'", tenant_name)
    list = query_single(sObjectType, query, tenant_name)
    return list[0] if list.length > 0
  end

  def openstack_domain_required?(_data)
    return true if config[:auth_uri].match(%r{/v3/})
    false
  end
end

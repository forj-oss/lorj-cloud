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

# Define Openstack update controller
class OpenstackController
  def update_router(obj_to_save, _hParams)
    router = obj_to_save[:object]
    # The optional external_gateway_info must be a The network_id for the
    # external gateway. It cannot be a Hash
    # See API : http://developer.openstack.org/api-ref-networking-v2.html
    router.external_gateway_info = router.external_gateway_info['network_id']
    # Save will restore the Hash.
    begin
      router.save
      true
    rescue => e
      Lorj.error "OpenStack: Router save error.\n%s\n%s",
                 e.message, e.backtrace.join("\n")
      false
    end
  end
end

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

# Defined HPCloud controller.
module HPCompute
  def self.get_server(oComputeConnect, sId)
    oComputeConnect.servers.get(sId)
  end

  def self.query_addresses(oComputeConnect, sQuery)
    oComputeConnect.addresses.all(sQuery)
  end

  def self.query_server(oComputeConnect, sQuery)
    oComputeConnect.servers.all(sQuery)
  end

  def self.query_image(oComputeConnect, sQuery)
    # HP Fog query is exact matching. No way to filter with a Regexp
    # Testing it and filtering it.
    # TODO: Be able to support Regexp in queries then extract all and filter.
    oComputeConnect.images.all(sQuery)
  end

  def self.query_flavor(oComputeConnect, sQuery)
    oComputeConnect.flavors.all(sQuery)
  end

  def self.create_server(oComputeConnect, options, oUser_data, oMeta_data)
    if oUser_data
      options[:user_data_encoded] = Base64.strict_encode64(oUser_data)
    end
    options[:metadata] = oMeta_data if oMeta_data
    server = oComputeConnect.servers.create(options)
    HPCompute.get_server(oComputeConnect, server.id) if server
  end

  def self.query_server_assigned_addresses(oComputeConnect, _oServer, sQuery)
    # CloudProcess used a simplified way to manage IPs.
    # Following is the translation to get the public IPs for the server

    result = []
    addresses = oComputeConnect.addresses.all
    addresses.each do |oElem|
      is_found = true
      sQuery.each do |key, value|
        if !oElem.attributes.key?(key) || oElem.attributes[key] != value
          is_found = false
          break
        end
      end
      result << oElem if is_found
    end
    result
  end

  def self.get_server_assigned_address(oComputeConnect, id)
    addresses = oComputeConnect.addresses.all
    addresses.each { |oElem| return oElem if oElem.attributes['id'] == id }
  end

  def self.server_assign_address(oComputeConnect, server)
    while server.state != 'ACTIVE'
      sleep(5)
      server = oComputeConnect.servers.get(server.id)
    end

    addresses = oComputeConnect.addresses.all
    address = nil
    # Search for an available IP
    addresses.each do |oElem|
      if oElem.fixed_ip.nil?
        address = oElem
        break
      end
    end

    if address.nil?
      # Create a new public IP to add in the pool.
      address = oComputeConnect.addresses.create
    end
    fail "No Public IP to assign to server '%s'", server.name if address.nil?
    address.server = server # associate the server
    address.reload
    # This function needs to returns a list of object.
    # This list must support the each function.
    address
  end

  def self.delete_server(oComputeConnect, server)
    oComputeConnect.servers.get(server.id).destroy
  end

  def self.get_image(oComputeConnect, oImageID)
    oComputeConnect.images.get(oImageID)
  end
end

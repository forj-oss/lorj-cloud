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

# Defined Openstack object get.
class OpenstackController
  def self.def_get(connection, name, property_name = nil)
    property_name = property_name.nil? ? "#{name}s" : property_name.to_s
    define_method("get_#{name}") do |hParams, sUniqId|
      required?(hParams, connection)
      hParams[connection].send(property_name).get(sUniqId)
    end
  end

  def_get :compute_connection, :server

  def_get :compute_connection, :image

  def_get :network_connection, :network

  def_get :compute_connection, :keypairs, :key_pairs

  def get_server_log(hParams, sUniqId)
    required?(hParams, :server)
    hParams[:server].console(sUniqId)
  end
end

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

# Defined Openstack object query.
class OpenstackController
  def self.def_basic_query(connection, name, property_name = nil)
    property_name = property_name.nil? ? name.to_s + 's' : property_name.to_s

    define_method("query_#{name}") do |hParams, _query|
      required?(hParams, connection)
      hParams[connection].send(property_name).all
    end
  end

  # Implementation of API supporting query Hash
  def self.def_simple_query(connection, name, property_name = nil)
    property_name = property_name.nil? ? name.to_s + 's' : property_name.to_s

    define_method("query_#{name}") do |hParams, query|
      required?(hParams, connection)
      hParams[connection].send(property_name).all query
    end
  end

  # Implementation of API NOT supporting query Hash
  # The function will filter itself.
  def self.def_complex_query(connection, name, property_name = nil)
    property_name = property_name.nil? ? name.to_s + 's' : property_name.to_s

    define_method("query_#{name}") do |hParams, query|
      required?(hParams, connection)

      key_pairs = hParams[connection].send(property_name).all
      results = []
      key_pairs.each do |sElem|
        selected = true
        attributes = sElem.instance_variable_get(:@attributes)
        query.each do |key, value|
          if attributes[key] != value
            selected = false
            break
          end
        end
        results.push sElem if selected
      end
      results
    end
  end

  def_simple_query :compute_connection, :tenant

  def_simple_query :compute_connection, :image

  def_simple_query :compute_connection, :flavor

  def_simple_query :compute_connection, :server

  def_simple_query :network_connection, :network

  def_simple_query :network_connection, :subnetwork, :subnets

  def_simple_query :network_connection, :router

  def_simple_query :network_connection, :port

  # def_simple_query :network_connection, :security_groups, :security_groups

  def_simple_query :network_connection, :rule, :security_group_rules

  def_complex_query :compute_connection, :keypairs, :key_pairs

  def_complex_query :compute_connection, :public_ip, :addresses

  def_complex_query :compute_connection, :tenants, :tenants

  def query_security_groups(hParams, query)
    required?(hParams, :network_connection)
    required?(hParams, :tenants)

    query[:tenant_id] = hParams[:tenants].id
    hParams[:network_connection].send(:security_groups).all query
  end
end

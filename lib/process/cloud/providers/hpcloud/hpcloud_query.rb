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

# Defined HPCloud object query.
class HpcloudController
  # Implementation of API NOT supporting query Hash
  # The function will filter itself.
  # It must support
  # - Regexp
  # - simple value equality
  def self.def_query(requires, name, property_name = nil)
    property_name = property_name.nil? ? name.to_s + 's' : property_name.to_s

    define_method("query_#{name}") do |hParams, query|
      requires = [requires] unless requires.is_a?(Array)
      requires.each { |r| required?(hParams, r) }

      connection = requires[0]

      yield hParams, query if block_given?

      func = hParams[connection].send(property_name).method(:all)
      if func.parameters.length > 0
        Lorj.debug(4, "'%s' uses HPCloud API filter feature.", __method__)
        objects = func.call ctrl_query_select(query, String)
      else
        objects = func.call
      end
      # Uses :[] or :<key> to match object and query attr.
      Lorj.debug(4, "'%s' gets %d records", __method__, objects.length)
      ctrl_query_each objects, query # Return the select objects.
    end
  end

  def_query :compute_connection, :tenant

  def_query :compute_connection, :image

  def_query :compute_connection, :flavor

  def_query :compute_connection, :server

  def_query :network_connection, :network

  def_query :network_connection, :subnetwork, :subnets

  def_query :network_connection, :router

  def_query :network_connection, :port

  def_query :network_connection, :security_groups, :security_groups

  def_query :network_connection, :rule, :security_group_rules

  def_query :compute_connection, :keypairs, :key_pairs

  def_query :compute_connection, :public_ip, :addresses

  def_query :compute_connection, :tenants, :tenants
end

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

# Defined Openstack object create.
class OpenstackController
  def create_security_groups(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :tenants)
    required?(hParams, :security_group)

    service = hParams[:network_connection]

    service.security_groups.create(:name => hParams[:security_group],
                                   :tenant_id => hParams[:tenants].id)
  end

  def create_network(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :network_name)

    hParams[:network_connection].networks.create(hParams[:hdata])
  end

  def create_subnetwork(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :network)

    netconn = hParams[:network_connection]
    netconn.subnets.create(
      :network_id => hParams[:network].id,
      :name => hParams[:subnetwork_name],
      :cidr => get_next_subnet(netconn),
      :ip_version => '4'
    )
  end

  def create_rule(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :security_groups)
    hParams[:network_connection].security_group_rules.create(hParams[:hdata])
  end

  def create_router(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :router_name)

    # Forcelly used admin_status_up to true. Coming from HPCloud.
    # But not sure if we need it or not.
    #  hParams[:hdata] = hParams[:hdata].merge(:admin_state_up => true)

    hParams[:network_connection].routers.create(hParams[:hdata])
  end

  def create_router_interface(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :router)
    required?(hParams, :subnetwork)

    service = hParams[:network_connection]
    router = hParams[:router]
    result = service.add_router_interface(router.id, hParams[:subnetwork].id)
    fail if result.status != 200
    result
  end

  def create_keypairs(hParams)
    required?(hParams, :compute_connection)
    required?(hParams, 'credentials#keypair_name')
    required?(hParams, :public_key)

    # API:
    # https://github.com/fog/fog/blob/master/lib/fog/openstack/docs/compute.md
    service = hParams[:compute_connection]
    service.key_pairs.create(:name => hParams['credentials#keypair_name'],
                             :public_key => hParams[:public_key])
  end

  def create_server(hParams)
    [:compute_connection, :image,
     :network, :flavor, :keypairs,
     :security_groups, :server_name].each do |required_param|
      required?(hParams, required_param)
    end

    options = {
      :name             => hParams[:server_name],
      :flavor_ref       => hParams[:flavor].id,
      :image_ref        => hParams[:image].id,
      :key_name         => hParams[:keypairs].name,
      :security_groups  => [hParams[:security_groups].name],
      :nics             => [{ :net_id => hParams[:network].id }]
    }

    if hParams[:user_data]
      options[:user_data_encoded] =
        Base64.strict_encode64(hParams[:user_data])
    end
    options[:metadata] = hParams[:meta_data] if hParams[:meta_data]

    compute_connect = hParams[:compute_connection]

    server = compute_connect.servers.create(options)
    compute_connect.servers.get(server.id) if server
  end

  def create_public_ip(hParams)
    required?(hParams, :compute_connection)
    required?(hParams, :server)

    compute_connect = hParams[:compute_connection]
    server = hParams[:server]

    Lorj.debug(3, "Waiting for server '%s' to become ready...", server.name)
    until server.ready?
      sleep(5)
      server = compute_connect.servers.get(server.id)

      if server.state == 'Error'
        controller_error('Unable to assign a Public IP to a server '\
                         "in error '%s'", server.name)
      end
    end

    # if 2 processes run in // to allocate a floating to different server
    # openstack can re-allocate and the last who set the server win.
    # So, we need to set it, and wait to see if the allocation is confirmed
    # To the current server.
    # This is required as there is no guarantee who did the last allocation
    # of this IP.
    # This should reduce strongly the risk but not completely.
    # The best approach is that openstack MUST required to disassociate before
    # associate...
    # And if the second want to do the same, an error should be reported and
    # a retry to be spawned.
    address = nil
    loop do
      address = addresses_all(hParams)
      Lorj.debug(5, "Trying to associate '%s' to '%s'.",
                 address.ip, server.name)

      address.server = server # associate the server
      sleep(1 + rand(3))
      address.reload
      break if address.instance_id == server.id
    end
    Lorj.debug(4, "'%s' is confirmed to be associated to '%s'.",
               address.ip, server.name)
    address
  end
end

# Internal functions
class OpenstackController # :nodoc:
  def addresses_all(hParams)
    addresses = hParams[:compute_connection].addresses.all
    # Search for an available IP
    loop do
      addresses.each { |elem| return elem if elem.fixed_ip.nil? }
      # If no IP are available, create a new one.
      Lorj.debug(3, 'No more Free IP. Allocate a new one.')
      create_floating_ip(hParams)
      addresses.reload
    end
  end

  def create_floating_ip(params)
    required?(params, :network_connection)
    required?(params, :external_network)

    network = params[:network_connection]
    ext_net = params[:external_network]

    # Create a new public IP to add in the pool.
    begin
      network.floating_ips.create(:floating_network_id => ext_net.id)
    rescue => e
      controller_error('Unable to get a new floating IP. %s', e)
    end
  end

  def get_next_subnet(oNetworkConnect)
    subnet_values = []
    subnets = oNetworkConnect.subnets.all

    subnets.each do|s|
      subnet_values.push(s.cidr)
    end

    gap = false
    count = 0
    range_used = []
    new_subnet = 0
    new_cidr = ''

    subnet_values = subnet_values.sort!

    subnet_values.each do|value|
      range_used.push(value[5])
    end

    range_used.each do |n|
      if count.to_i == n.to_i
      else
      new_subnet = count
      gap = true
      break
      end
      count += 1
    end

    if gap
      new_cidr = format('10.0.%s.0/24', count)
    else
      max_value = range_used.max
      new_subnet = max_value.to_i + 1
      new_cidr = format('10.0.%s.0/24', new_subnet)
    end
    new_cidr
  rescue => e
    Logging.error("%s\n%s", e.message, e.backtrace.join("\n"))
  end
end

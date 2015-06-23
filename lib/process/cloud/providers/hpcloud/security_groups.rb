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

# HPCloud security groups
module HPSecurityGroups
  def self.create_sg(oNetwork, name, description)
    params = { :name => name }
    params[:description] = description if description
    oNetwork.security_groups.create(params)
  end

  def self.create_rule(oNetwork, hData)
    oNetwork.security_group_rules.create(hData)
  end

  def self.delete_rule(oNetwork, rule_id)
    oNetwork.security_group_rules.get(rule_id).destroy
  end
end

# HPCloud keypairs
module HPKeyPairs
  def self.get_keypair(oComputeConnect, sId)
    oComputeConnect.key_pairs.get(sId)
  end

  def self.create_keypair(oComputeConnect, name, pubkey)
    oComputeConnect.key_pairs.create(:name => name, :public_key => pubkey)
  end
end

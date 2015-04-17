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

# This file is given as an example.

# This class is automatically derived from ForjCloudBase and ForjProcess
class Mycloud
  def provider_network_new
    Fog::Network.new({ :provider => :mycloud }.merge(hget_cloudObjMapping))
  end

  def provider_query_network(oNetwork, name)
    oNetwork.networks.all(:name => name)
  end

  def provider_create_network(oNetwork, name)
    oNetwork.networks.create(:name => name)
  end
end

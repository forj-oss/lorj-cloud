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

cloud_path = File.dirname(__FILE__)

# Define model

lorj_objects = %w(common connection network subnetwork router
                  external_network security_groups rules
                  keypairs images flavor internet_network server public_ip
                  server_log internet_server)

lorj_objects.each do |name|
  load File.join(cloud_path, 'cloud', 'process', name + '.rb')
end

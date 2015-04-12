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

# rubocop: disable Style/ClassAndModuleChildren

# SERVER Console Object
# Object representing the console log attached to a server
class Lorj::BaseDefinition
  define_obj(:server_log,

             :get_e => :forj_get_server_log
            )

  obj_needs :CloudObject,  :server
  obj_needs :data,         :log_lines
  undefine_attribute :name
  undefine_attribute :id
  def_attribute :output
end

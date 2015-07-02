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

# Defined Openstack object refresh.
class OpenstackController
  def self.def_refresh(name)
    define_method("refresh_#{name}") do |object|
      ret = false
      if object.class.method_defined?(:reload)
        begin
          object.reload
        rescue => e
          PrcLib.error("'%s': %s", object.class, e)
        else
          Lorj.debug(4, "'%s' refreshed '%s'", __method__, object.class)
          ret = true
        end
      end
      ret
    end
  end

  dcl = %w(server)

  dcl.each { |t| def_refresh t.to_sym }
end

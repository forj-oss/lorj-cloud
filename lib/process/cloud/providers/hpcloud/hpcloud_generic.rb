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

# Define the HPCloud controller interface with Lorj.
# Lorj uses following functions:
# - create(object_type, params)
# - delete(object_type, params)
# - get(object_type, id, param)
# - query(object_type, query, params)
# - update(object_type, object, param)
#
# The controller driver will need to dispatch the task to
# the real FOG task.
#
# Currently, Hpcloud controller is moving a more generic ruby code.
# and only query has been implemented that way, in order to use
# Most of lorj and FOG features.
class HpcloudController
  def self.def_cruds(*crud_types)
    crud_types.each do |crud_type|
      case crud_type
      when :create, :delete
        base_method(crud_type)
      when :query, :get
        query_method(crud_type)
      when :update
        update_method(crud_type)
      end
    end
  end

  def self.update_method(crud_type)
    define_method(crud_type) do |sObjectType, obj, hParams|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, obj, hParams)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  def self.query_method(crud_type)
    define_method(crud_type) do |sObjectType, sCondition, hParams|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, hParams, sCondition)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  def self.base_method(crud_type)
    define_method(crud_type) do |sObjectType, hParams|
      method_name = "#{crud_type}_#{sObjectType}"
      if self.class.method_defined? method_name
        send(method_name, hParams)
      else
        controller_error "'%s' is not a valid object for '%s'",
                         sObjectType, crud_type
      end
    end
  end

  # Define the Openstack controller handlers
  # def_cruds :create, :delete, :get, :query, :update
  # Moving to use the Openstack code model.
  def_cruds :query
end

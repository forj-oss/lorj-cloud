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

# ---------------------------------------------------------------------------
# Image management
# ---------------------------------------------------------------------------
class CloudProcess
  def forj_get_or_create_image(sCloudObj, hParams)
    image_name = hParams[:image_name]
    PrcLib.state("Searching for image '%s'", image_name)

    search_the_image(sCloudObj, { :name => image_name }, hParams)
    # No creation possible.
  end

  def search_the_image(sCloudObj, sQuery, hParams)
    image_name = hParams[:image_name]
    images = forj_query_image(sCloudObj, sQuery, hParams)
    case images.length
    when 0
      PrcLib.info("No image '%s' found", image_name)
      nil
    when 1
      PrcLib.info("Found image '%s'.", image_name)
      images[0, :ssh_user] = ssh_user(images[0, :name])
      images[0]
    else
      PrcLib.info("Found several images '%s'. Selecting the first "\
                  "one '%s'", image_name, images[0, :name])
      images[0, :ssh_user] = ssh_user(images[0, :name])
      images[0]
    end
  end

  def forj_query_image(sCloudObj, sQuery, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      images = controller_query(sCloudObj, sQuery)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
    add_ssh_user(images)
    images
  end

  def add_ssh_user(images)
    images.each do |image|
      image[:ssh_user] = ssh_user(image[:name])
    end
  end

  def ssh_user(image_name)
    return 'fedora' if image_name =~ /fedora/i
    return 'centos' if image_name =~ /centos/i
    'ubuntu'
  end

  def forj_get_image(sCloudObj, sId, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      image = controller_get(sCloudObj, sId)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
    add_ssh_user([image])
    image
  end
end

# ************************************ Image Object
# Identify image
class Lorj::BaseDefinition # rubocop: disable Style/ClassAndModuleChildren
  define_obj(:image,

             :create_e => :forj_get_or_create_image,
             :query_e => :forj_query_image,
             :get_e => :forj_get_image
            #         :update_e   => :forj_update_image
            #         :delete_e   => :forj_delete_image
            )

  obj_needs :CloudObject,  :compute_connection
  obj_needs :data,         :image_name,          :for => [:create_e]
end

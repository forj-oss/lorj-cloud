require 'lorj_cloud/version'

require 'lorj'

Lorj.declare_process('cloud', File.dirname(__FILE__),
                     :controllers_dir => 'providers', :lib_name => 'lorj_cloud')

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

# Keypair management
class CloudProcess
  # KeyPair Create Process Handler
  # The process implemented is:
  # * Check local SSH keypairs with given ':keypair_name'
  # * Check remote keypair existence
  # * Compare and warn if needed.
  # * Import public key found if missing remotely and name it.
  #
  # Return:
  # - keypair : Lorj::Data keypair object. Following additional data should be
  #             found in the keypair attributes
  #   - :coherent        : Boolean. True, if the local keypair (public AND
  #                        private) is coherent with remote keypair found in
  #                        the cloud
  #   - :private_key_file: String. Path to local private key file
  #   - :public_key_file : String. Path to local public key file
  #   - :public_key      : String. Public key content. (config[:public_key] is
  #                        also set - Used to import it)
  #
  def forj_get_or_create_keypair(sCloudObj, hParams)
    keypair_name = hParams['credentials#keypair_name']

    PrcLib.state("Searching for keypair '%s'", keypair_name)

    keypair = forj_get_keypair(sCloudObj, keypair_name, hParams)
    if keypair.empty? &&
       hParams.exist?(:keypair_path) && hParams.exist?(:keypair_base)

      loc_kpair = keypair_detect(keypair_name, hParams[:keypair_path],
                                 hParams[:keypair_base])
      keypair = keypair_import(hParams, loc_kpair)
    else
      if keypair.empty?
        PrcLib.warning("keypair '%s' was not found.", keypair_name)
      else
        keypair_display(keypair)
      end
    end
    keypair
  end

  # Query cloud keypairs and check coherence with local files
  # of same name in forj files located by :keypair_path
  def forj_query_keypairs(sCloudObj, sQuery, hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      keypairs = controller_query(sCloudObj, sQuery)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
    return keypairs unless hParams.exist?(:keypair_path) &&
                           hParams.exist?(:keypair_base)
    # Looping on keypairs to identify if they have a valid local ssh key.
    keypair_path = File.expand_path(hParams[:keypair_path])
    keypair_base = File.expand_path(hParams[:keypair_base])

    keypairs.each do |keypair|
      loc_kpair = keypair_detect(keypair_name, keypair_path, keypair_base)
      keypair_files_detected(keypair, loc_kpair)
    end
    keypairs
  end

  # Get cloud keypair and check coherence with local files
  # of same name in forj files
  def forj_get_keypair(sCloudObj, keypair_name, hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      keypair = controller_get(sCloudObj, keypair_name)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end

    return keypair unless hParams.exist?(:keypair_path)
    keypair_path = File.expand_path(hParams[:keypair_path])
    loc_kpair = keypair_detect(keypair_name, keypair_path, keypair_name)
    keypair_files_detected(keypair, loc_kpair) unless keypair.empty?
    keypair
  end
end

# ************************************ keypairs Object
# Identify keypairs
class Lorj::BaseDefinition
  define_obj(:keypairs,

             :create_e => :forj_get_or_create_keypair,
             :query_e => :forj_query_keypairs,
             :get_e => :forj_get_keypair
            #         :delete_e   => :forj_delete_keypair
            )

  obj_needs :CloudObject,  :compute_connection
  obj_needs :data,         'credentials#keypair_name', :for => [:create_e]

  obj_needs_optional
  # By default optional. But required by the ssh case if needed.
  obj_needs :data,         :keypair_path
  obj_needs :data,         :keypair_base
  # By default optional. But required by the import case if needed.
  obj_needs :data,         :public_key, :for => [:create_e]

  def_attribute :public_key
end

# Keypair management: Internal process functions
class CloudProcess
  # Function to display information about keypair object found.
  #
  def keypair_display(keypair)
    PrcLib.info("Found keypair '%s'.", keypair[:name])

    unless keypair.exist?(:keypair_path)
      PrcLib.info('Unable to verify your keypair with your local files.'\
                  ' :keypair_path is missing.')
      return
    end
    private_key_file = File.join(keypair[:keypair_path],
                                 keypair[:private_key_name])
    public_key_file = File.join(keypair[:keypair_path],
                                keypair[:public_key_name])

    PrcLib.info("Found openssh private key file '%s'.",
                private_key_file) if keypair[:private_key_exist?]
    PrcLib.info("Found openssh public key file '%s'.",
                public_key_file) if keypair[:public_key_exist?]

    unless keypair[:public_key_exist?]
      name = keypair[:name]
      PrcLib.warning("The local public key file '%s' is missing.\n"\
                     "As the keypair name '%s' already exists in your cloud, "\
                     'you will need to get the original SSH keypair files '\
                     "used to create the keypair name '%s'. Otherwise, you "\
                     "won't be able to use it to connect to a box configured"\
                     " with '%s'."\
                     "\nPublic key found in the cloud:\n%s",
                     public_key_file, name, name, name,
                     keypair[:public_key])
      return
    end

    if keypair[:coherent]
      PrcLib.info("keypair '%s' local files are coherent with keypair in "\
                  'your cloud service. You will be able to use your local '\
                  'keys to connect to any box configured with this keypair '\
                  'name, over SSH.', keypair[:name])
    else
      PrcLib.warning("Your local public key file '%s' is incoherent with "\
                     "public key attached to the keypair '%s' in your cloud."\
                     " You won't be able to access your box with this keypair."\
                     "\nPublic key found in the cloud:\n%s",
                     public_key_file, keypair[:name], keypair[:public_key])
    end
  end
end

# Keypair management: Internal process functions
class CloudProcess
  # Function to update a keypair object with ssh files found in :keypair_path
  #
  def keypair_files_detected(keypair, loc_kpair)
    keypair[:private_key_exist?] = loc_kpair[:private_key_exist?]
    keypair[:public_key_exist?] = loc_kpair[:public_key_exist?]
    keypair[:private_key_name] = loc_kpair[:private_key_name]
    keypair[:public_key_name] = loc_kpair[:public_key_name]
    keypair[:keypair_path] = loc_kpair[:keypair_path]
    keypair[:coherent] = coherent_keypair?(loc_kpair, keypair)
  end

  def keypair_import(hParams, loc_kpair)
    PrcLib.fatal(1, "Unable to import keypair '%s'. "\
                    "Public key file '%s' is not found. "\
                    "Please run 'forj setup %s'",
                 hParams['credentials#keypair_name'],
                 File.join(loc_kpair[:keypair_path],
                           loc_kpair[:public_key_name]),
                 config[:account_name]) unless loc_kpair[:public_key_exist?]
    public_key_file = File.join(loc_kpair[:keypair_path],
                                loc_kpair[:public_key_name])

    begin
      public_key = File.read(public_key_file)
    rescue => e
      PrcLib.fatal(1, "Unable to import keypair '%s'. '%s' is "\
                      "unreadable.\n%s", hParams['credentials#keypair_name'],
                   loc_kpair[:public_key_file],
                   e.message)
    end
    keypair = create_keypair(:keypairs, :public_key => public_key)

    return nil if keypair.nil?

    # Adding information about SSH key files.
    keypair_files_detected(keypair, loc_kpair)

    keypair
  end

  def create_keypair(sCloudObj, hParams)
    key_name = hParams['credentials#keypair_name']
    PrcLib.state("Importing keypair '%s'", key_name)
    ssl_error_obj = SSLErrorMgt.new
    begin
      keypair = controller_create(sCloudObj, hParams)
      PrcLib.info("Keypair '%s' imported.", keypair[:name])
    rescue StandardError => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
      PrcLib.error "error importing keypair '%s'", key_name
    end
    keypair
  end

  # Build keypair data information structure with files found in
  # local filesystem. Take care of priv with or without .pem
  # and pubkey with pub.
  # :keypair_path data settings is changing to become just a path to
  # the keypair files, the base keypair.
  # Which will introduce a :keypair_base in the setup.
  def keypair_detect(keypair_name, key_fullpath, key_basename = nil)
    # When uses key_basename, we switch to the new model
    # using :keypair_path and :keypair_base in setup
    if key_basename.nil?
      key_basename = File.basename(key_fullpath)
      key_path = File.expand_path(File.dirname(key_fullpath))
    else
      key_path = File.expand_path(key_fullpath)
    end

    obj_match = key_basename.match(/^(.*?)(\.pem|\.pub)?$/)
    key_basename = obj_match[1]

    private_key_ext, files = _check_key_file(key_path, key_basename,
                                             ['', '.pem'])

    if private_key_ext
      priv_key_exist = true
      priv_key_name = key_basename + private_key_ext
    else
      files.each do |temp_file|
        PrcLib.warning('keypair_detect: Private key file name detection has '\
                       "detected '%s' as a directory. Usually, it should be a "\
                       'private key file. Please check.',
                       temp_file) if File.directory?(temp_file)
      end
      priv_key_exist = false
      priv_key_name = key_basename
    end

    pub_key_exist = File.exist?(File.join(key_path, key_basename + '.pub'))
    pub_key_name = key_basename + '.pub'

    # keypair basic structure
    { :keypair_name     => keypair_name,
      :keypair_path     => key_path,      :key_basename       => key_basename,
      :private_key_name => priv_key_name, :private_key_exist? => priv_key_exist,
      :public_key_name  => pub_key_name,  :public_key_exist?  => pub_key_exist
    }
  end

  def _check_key_file(key_path, key_basename, extensions)
    found_ext = nil
    files = []
    extensions.each do |ext|
      temp_file = File.join(key_path, key_basename + ext)
      if File.exist?(temp_file) && !File.directory?(temp_file)
        found_ext = ext
        files << temp_file
      end
    end
    [found_ext, files]
  end

  def get_keypairs_path(hParams, hKeys)
    keypair_name = hParams['credentials#keypair_name']

    if hKeys[:private_key_exist?]
      hParams[:private_key_file] = File.join(hKeys[:keypair_path],
                                             hKeys[:private_key_name])
      PrcLib.info("Openssh private key file '%s' exists.",
                  hParams[:private_key_file])
    end
    if hKeys[:public_key_exist?]
      hParams[:public_key_file] = File.join(hKeys[:keypair_path],
                                            hKeys[:public_key_name])
    else
      PrcLib.fatal(1, 'Public key file is not found. Please run'\
                      " 'forj setup %s'", config[:account_name])
    end

    PrcLib.state("Searching for keypair '%s'", keypair_name)

    hParams
  end

  # Check if 2 keypair objects are coherent (Same public key)
  # Parameters:
  # - +loc_kpair+ : Keypair structure representing local files existence.
  #                     see keypair_detect
  # - +keypair+       : Keypair object to check.
  #
  # return:
  # - coherent : Boolean. True if same public key.
  def coherent_keypair?(loc_kpair, keypair)
    # send keypairs by parameter
    is_coherent = false

    pub_keypair = keypair[:public_key]

    # Check the public key with the one found here, locally.
    if !pub_keypair.nil? && pub_keypair != ''
      return false unless loc_kpair[:public_key_exist?]
      begin
        loc_pubkey = File.read(File.join(loc_kpair[:keypair_path],
                                         loc_kpair[:public_key_name]))
      rescue => e
        PrcLib.error("Unable to read '%s'.\n%s",
                     loc_kpair[:public_key_file], e.message)
      else
        if loc_pubkey.split(' ')[1].strip == pub_keypair.split(' ')[1].strip
          is_coherent = true
        end
      end
    else
      PrcLib.warning('Unable to verify keypair coherence with your local '\
                     'SSH keys. No public key (:public_key) provided.')
    end
    is_coherent
  end
end

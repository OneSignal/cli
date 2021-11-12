class OSProject
  attr_reader :type
  attr_reader :dir
  attr_reader :lang
  attr_reader :os_app_id

  # Platform APIs
  attr_accessor :fcm_id
  attr_accessor :apns_id

  def initialize(type, dir, lang, os_app_id)
    @type = type
    @dir = dir
    @lang = lang
    @os_app_id = os_app_id
  end
  
  # @abstract add_sdk is expected to be implemented by subclasses
  # @!method add_sdk!
  #   Conduct the initial-setup process to add the latest OS SDK to the project
  def add_sdk!
    puts "type:" + self.type + " dir: " + self.dir
    puts "lang:" + self.lang + " os_app_id: " + self.os_app_id
    puts "apns_id:" + (self.apns_id || 'nil') + " fcm_id: " + (self.fcm_id || 'nil')
  end

  # @abstract has_sdk? is expected to be implemented by subclasses
  # @!method has_sdk?
  #   Returns True if the project already has an SDK initialized
  def has_sdk?
    raise Exception.new "Not Implemented"
  end

  def self.version
    '0.0.0'
  end

  def self.os
    'mac'
  end

  def self.tool_name
    'onesignal-cli'
  end
  
  def self.default_command
    'install-sdk'
  end
end

class OSProject::Dummy < OSProject
  # this is a temporary placeholder
  attr_accessor :has_sdk

  def initialize(dir, target, lang, os_app_id)
    @has_sdk = false
    super(:dummy, dir, lang, os_app_id)
  end
  def add_sdk!
    @has_sdk = true
  end
  def has_sdk?
    return self.has_sdk
  end
end

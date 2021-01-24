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

  def _gsub_file(path, regexp, *args, &block)
    content = File.read(path).gsub(regexp, *args, &block)
    File.open(path, 'w') { |file| file.write(content) }
  end

  # @abstract add_sdk is expected to be implemented by subclasses
  # @!method add_sdk
  #   Conduct the initial-setup process to add the latest OS SDK to the project
  def add_sdk
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
end

class OSProject::IOS < OSProject
  # this is a temporary placeholder
  attr_accessor :has_sdk

  def initialize(dir, lang, os_app_id)
    @has_sdk = false
    super('ios', dir, lang, os_app_id)
  end
  def add_sdk
    @has_sdk = true
  end
  def has_sdk?
    return self.has_sdk
  end
end

class OSProject::GoogleAndroid < OSProject
  attr_accessor :app_class_location

  @@kotlin_init_code = 'INIT'
  @@java_init_code = 'INIT'

  def initialize(dir, lang, os_app_id)
    super('android', dir, lang, os_app_id)
  end
  
  def add_sdk
    # TODO: test for reqs
    # add deps to /build.gradle
    _gsub_file(dir + '/build.gradle', /(classpath 'com.android.tools.build:gradle:3.5.3')/, '\1')
    # add deps to /app/build.gradle
    _gsub_file(dir + '/app/build.gradle', /(implementation 'com.google.android.material:material:1.0.0')/, '\1ONESIGNAL\n')
    # TODO: add init code to Application class
    # _gsub_file(dir + self.app_class_location, //, '\1')
    # TODO: prompt for custom notif icons & addl features
  end

  def has_sdk?
    # TODO: more robust testing
    return File.readlines(dir + '/app/build.gradle').grep(/ONESIGNAL/).any?
  end
end

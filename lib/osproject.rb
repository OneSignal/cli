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

  def _gsub_file(path, match, replace, &block)
    content = File.read(path).gsub(regexp, replace, &block)
    File.open(path, 'w') { |file| file.write(content) }
  end

  def _sub_file(path, match, replace, &block)
    content = File.read(path).sub(regexp, replace, &block)
    File.open(path, 'w') { |file| file.write(content) }
  end

  def _insert_lines(file, marker, insert)
    str = Regexp::quote(marker)
    if insert.is_a?
      _sub_file(file, /^(\s*)(#{str})/) do |indent, prevln|
        prevln + "\n" + indent + lines.join("\n" + indent)
      end
    else
      _sub_file(file, /^(\s*)(#{str})/, '\1\2' + "\n" + '\1' + add)
    end
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
end

class OSProject::IOS < OSProject
  # this is a temporary placeholder
  attr_accessor :has_sdk

  def initialize(dir, lang, os_app_id)
    @has_sdk = false
    super(:ios, dir, lang, os_app_id)
  end
  def add_sdk!
    @has_sdk = true
  end
  def has_sdk?
    return self.has_sdk
  end
end

class OSProject::GoogleAndroid < OSProject
  attr_accessor :app_class_location

  def initialize(dir, lang, os_app_id)
    super(:googleandroid, dir, lang, os_app_id)
  end
  
  def add_sdk!
    # TODO: test for reqs
    #
    # TODO: this gradle tack is a very brittle approach.
    # add deps to /build.gradle
    _insert_lines(dir + '/build.gradle', "jcenter()", "gradlePluginPortal()")
    _insert_lines(dir + '/build.gradle', "classpath 'com.android.tools.build:gradle:3.5.3'", "classpath 'gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]'")
    # add deps to /app/build.gradle
    _insert_lines(dir + '/app/build.gradle', "implementation 'com.google.android.material:material:1.0.0'", "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'")
    _insert_lines(dir + '/app/build.gradle', "apply plugin: 'com.android.application'", "plugins { id 'com.onesignal.androidsdk.onesignal-gradle-plugin' }")

    # add OS API key to Application class
    if self.lang == "java"
      _sub_file(dir + '/' + self.app_class_location, /^(import \w*;)/, '\1' + "import com.onesignal.OneSignal;")
      _sub_file(dir + '/' + self.app_class_location, /(\w+ extends Application {)/, '\1' + 'private static final String ONESIGNAL_APP_ID = "' + self.os_app_id + '";')
      _insert_lines(dir + '/' + self.app_class_location, 'super.onCreate();', [
        "// Enable verbose OneSignal logging to debug issues if needed.",
        "// It is recommended you remove this after validating your implementation.",
        "OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE);",
        "// OneSignal Initialization",
        "OneSignal.initWithContext(this);",
        "OneSignal.setAppId(ONESIGNAL_APP_ID);"
      ])
    elsif self.lang == "kotlin"
      _sub_file(dir + '/' + self.app_class_location, /^(import \w*;)/, '\1' + 'import com.onesignal.OneSignal')
      _sub_file(dir + '/' + self.app_class_location, /^(import \w*;)/, '\1' + 'const val ONESIGNAL_APP_ID = "' + self.os_app_id + '"')
      _insert_lines(dir + '/' + self.app_class_location, 'super.onCreate()', [
        "// Enable verbose OneSignal logging to debug issues if needed.",
        "// It is recommended you remove this after validating your implementation.",
        "OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE)",
        "// OneSignal Initialization",
        "OneSignal.initWithContext(this)",
        "OneSignal.setAppId(ONESIGNAL_APP_ID)"
      ])
    else 
      raise "Don't know to handle #{lang}"
    end
  end

  def has_sdk?
    # TODO: more robust testing
    return File.readlines(dir + '/app/build.gradle').grep(/OneSignal/).any?
  end
end

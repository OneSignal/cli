require_relative 'osproject'
require_relative 'osproject_helpers'

class OSProject::GoogleAndroid < OSProject
  attr_accessor :app_class_location

  def initialize(dir, app_class_location, lang, os_app_id)
    @app_class_location = app_class_location
    super(:googleandroid, dir, lang, os_app_id)
  end
  
  def add_sdk!
    # TODO: test for reqs
    if app_class_location == nil
      raise 
    end
    #
    # TODO: this gradle tack is a very brittle approach.
    # add deps to /build.gradle
    _insert_lines(dir + '/build.gradle', 
                  Regexp.quote("jcenter()"),
                  "gradlePluginPortal()")
    _insert_lines(dir + '/build.gradle',
                  Regexp.quote("classpath 'com.android.tools.build:gradle:[^']*'"),
                  "classpath 'gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]'")
    # add deps to /app/build.gradle
    _insert_lines(dir + '/app/build.gradle',
                  Regexp.quote("implementation 'com.google.android.material:material:1.0.0'"),
                  "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'")
    _insert_lines(dir + '/app/build.gradle',
                  Regexp.quote("apply plugin: 'com.android.application'"),
                  "plugins { id 'com.onesignal.androidsdk.onesignal-gradle-plugin' }")

    # add OS API key to Application class
    if self.lang == "java"
      _sub_file(dir + '/' + app_class_location,
                /^(import \w*;)/,
                '\1' + "import com.onesignal.OneSignal;")
      _sub_file(dir + '/' + app_class_location,
                /(\w+ extends Application {)/, 
                '\1' + 'private static final String ONESIGNAL_APP_ID = "' + self.os_app_id + '";')
      _insert_lines(dir + '/' + app_class_location, 
                    'super\.onCreate\(\);?', [
                      "// Enable verbose OneSignal logging to debug issues if needed.",
                      "// It is recommended you remove this after validating your implementation.",
                      "OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE);",
                      "// OneSignal Initialization",
                      "OneSignal.initWithContext(this);",
                      "OneSignal.setAppId(ONESIGNAL_APP_ID);"
      ])
    elsif self.lang == "kotlin"
      _sub_file(dir + '/' + app_class_location,
                /^(import \w*;)/,
                '\1' + 'import com.onesignal.OneSignal')
      _sub_file(dir + '/' + app_class_location,
                /^(import \w*;)/,
                '\1' + 'const val ONESIGNAL_APP_ID = "' + self.os_app_id + '"')
      _insert_lines(dir + '/' + app_class_location,
                    Regexp.quote('super.onCreate()'), [
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

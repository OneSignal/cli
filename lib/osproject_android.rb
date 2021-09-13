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

    app_dir = app_class_location.split('/', -1)[0]

    #
    # TODO: this gradle tack is a very brittle approach.
    # add deps to /build.gradle
    _insert_lines(dir + '/build.gradle', 
                  Regexp.quote("jcenter()"),
                  "gradlePluginPortal()")
    _insert_lines(dir + '/build.gradle',
                  "classpath 'com.android.tools.build:gradle:[^']*'",
                  "classpath 'gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]'")
    _insert_lines(dir + '/build.gradle',
                  "classpath \"com.android.tools.build:gradle:[^']*\"",
                  "classpath \"gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]\"")
    # add deps to /app/build.gradle
    _insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "implementation 'com.google.android.material:material:[^']*'",
                  "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'")
    _insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "implementation \"com.google.android.material:material:[^']*\"",
                  "implementation \"com.onesignal:OneSignal:[4.0.0, 4.99.99]\"")
    _insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "apply plugin: 'com.android.application'",
                  "apply plugin: 'com.onesignal.androidsdk.onesignal-gradle-plugin'")
    _insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "id 'com.android.application'",
                  "id 'com.onesignal.androidsdk.onesignal-gradle-plugin'")

    # add OS API key to Application class
    if "#{self.lang}" == "java"
      _insert_lines(dir + '/' + app_class_location,
                "import [a-zA-Z.]+;",
                "import com.onesignal.OneSignal;")
      _insert_lines(dir + '/' + app_class_location,
                "public class [a-zA-Z\s]+{",
                "\s\s\s\sprivate static final String ONESIGNAL_APP_ID = \"" + self.os_app_id + "\";\n")
      _sub_file(dir + '/' + app_class_location,
                /super.onCreate\(\);\s/,
               "super.onCreate();
        // Enable verbose OneSignal logging to debug issues if needed.
        // It is recommended you remove this after validating your implementation.
        OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE);
        // OneSignal Initialization
        OneSignal.initWithContext(this);
        OneSignal.setAppId(ONESIGNAL_APP_ID);\n")
    elsif "#{self.lang}" == "kotlin"
      _insert_lines(dir + '/' + app_class_location,
                "import [a-zA-Z.]+",
                'import com.onesignal.OneSignal')
      _insert_lines(dir + '/' + app_class_location,
                "class [a-zA-Z\s:()]+{",
                "\s\s\s\sval ONESIGNAL_APP_ID = \"" + self.os_app_id + "\"\n")
      _sub_file(dir + '/' + app_class_location,
                       /super.onCreate\(\)\s/,
                      "super.onCreate()
        // Enable verbose OneSignal logging to debug issues if needed.
        // It is recommended you remove this after validating your implementation.
        OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE)
        // OneSignal Initialization
        OneSignal.initWithContext(this)
        OneSignal.setAppId(ONESIGNAL_APP_ID)\n")
    else 
      raise "Don't know to handle #{lang}"
    end
  end

  def has_sdk?
    # TODO: more robust testing
    return File.readlines(dir + '/app/build.gradle').grep(/OneSignal/).any?
  end
end

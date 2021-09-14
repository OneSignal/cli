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
    check_insert_lines(dir + '/build.gradle', 
                  Regexp.quote("mavenCentral()"),
                  "gradlePluginPortal()")
    check_insert_lines(dir + '/build.gradle', 
                  Regexp.quote("jcenter()"),
                  "gradlePluginPortal()")
    check_insert_lines(dir + '/build.gradle',
                  "classpath 'com.android.tools.build:gradle:[^']*'",
                  "classpath 'gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]'")
    check_insert_lines(dir + '/build.gradle',
                  "classpath \"com.android.tools.build:gradle:[^']*\"",
                  "classpath \"gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]\"")
    # add deps to /app/build.gradle
    check_insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "implementation 'androidx.appcompat:appcompat:[^']*'",
                  "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'")
    check_insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "implementation \"androidx.appcompat:appcompat:[^']*\"",
                  "implementation \"com.onesignal:OneSignal:[4.0.0, 4.99.99]\"")

    check_insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "implementation 'com.google.android.material:material:[^']*'",
                  "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'")
    check_insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "implementation \"com.google.android.material:material:[^']*\"",
                  "implementation \"com.onesignal:OneSignal:[4.0.0, 4.99.99]\"")

    check_insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "apply plugin: 'com.android.application'",
                  "apply plugin: 'com.onesignal.androidsdk.onesignal-gradle-plugin'")
    check_insert_lines(dir + '/' + app_dir + '/build.gradle',
                  "id 'com.android.application'",
                  "id 'com.onesignal.androidsdk.onesignal-gradle-plugin'")

    begin 
      content = File.read(dir + '/' + app_class_location)
    rescue
      directory_split = app_class_location.split('/', -1)

      application_name = directory_split[-1].split(".")[0]
      com_index = directory_split.index "com"
      range = directory_split.length - 2
      package_directory = directory_split.slice(com_index..range)
     
      File.open(dir + '/' + app_class_location, "w") do |f| 
        if "#{self.lang}" == "java"    
          f.write("package #{package_directory.join(".")};\n\n")
          f.write("import android.app.Application;\n\n")
          f.write("public class #{application_name} extends Application {\n")
          f.write("\s\s\s\s@Override\n")
          f.write("\s\s\s\spublic void onCreate() {\n")
          f.write("\s\s\s\s\s\ssuper.onCreate();\n")
          f.write("\s\s\s\s}\n")
          f.write("}")
        elsif "#{self.lang}" == "kotlin"
          f.write("package #{package_directory.join(".")}\n\n")
          f.write("import android.app.Application\n\n")
          f.write("class #{application_name} : Application() {\n")
          f.write("\s\s\s\soverride fun onCreate() {\n")
          f.write("\s\s\s\s\s\ssuper.onCreate()\n")
          f.write("\s\s\s\s}\n")
          f.write("}")
        end
      end

      _insert_lines(dir + '/' + app_dir + '/src/main/AndroidManifest.xml',
                "<application",
                "\s\sandroid:name=\"#{application_name}\"")
    end 

    # add OS API key to Application class
    if "#{self.lang}" == "java"
      check_insert_lines(dir + '/' + app_class_location,
                "import [a-zA-Z.]+;",
                "import com.onesignal.OneSignal;")
      check_insert_lines(dir + '/' + app_class_location,
                "public class [a-zA-Z\s]+{",
                "\s\s\s\sprivate static final String ONESIGNAL_APP_ID = \"" + self.os_app_id + "\";\n")
      check_insert_block(dir + '/' + app_class_location,
                /super.onCreate\(\);\s/,
               "OneSignal.setAppId",
               "\s\s// Enable verbose OneSignal logging to debug issues if needed.
        // It is recommended you remove this after validating your implementation.
        OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE);
        // OneSignal Initialization
        OneSignal.initWithContext(this);
        OneSignal.setAppId(ONESIGNAL_APP_ID);\n")
    elsif "#{self.lang}" == "kotlin"
      check_insert_lines(dir + '/' + app_class_location,
                "import [a-zA-Z.]+",
                'import com.onesignal.OneSignal')
      check_insert_lines(dir + '/' + app_class_location,
                "class [a-zA-Z\s:()]+{",
                "\s\s\s\sprivate val oneSignalAppId = \"" + self.os_app_id + "\"\n")
      check_insert_block(dir + '/' + app_class_location,
                 /super.onCreate\(\)\s/,
                 "OneSignal.setAppId",
                 "\s\s// Enable verbose OneSignal logging to debug issues if needed.
        // It is recommended you remove this after validating your implementation.
        OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE)
        // OneSignal Initialization
        OneSignal.initWithContext(this)
        OneSignal.setAppId(oneSignalAppId)\n")
    else 
      raise "Don't know to handle #{lang}"
    end
  end

  def check_insert_lines(directory, regex, addition)
    if !File.readlines(directory).any?{ |l| l[addition] }
      _insert_lines(directory, regex, addition)
    end
  end

  def check_insert_block(directory, regex, addition, addition_block)
    if !File.readlines(directory).any?{ |l| l[addition] }
      _insert_lines(directory, regex, addition_block)
    end
  end

  def has_sdk?
    # TODO: more robust testing
    return File.readlines(dir + '/app/build.gradle').grep(/OneSignal/).any?
  end
end

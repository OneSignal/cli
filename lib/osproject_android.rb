require_relative 'osproject'
require_relative 'osproject_helpers'

class OSProject::GoogleAndroid < OSProject
  attr_accessor :app_class_location

  def initialize(dir, app_class_location, os_app_id)
    @app_class_location = app_class_location

    directory_split = app_class_location.split('/', -1)
    lang = directory_split[-1].split(".")[1]

    unless lang == "java" || lang == "kt"
      puts 'Invalid language (java or kotlin)'
      exit(1)
    end

    super(:googleandroid, dir, lang, os_app_id)
  end
  
  def add_sdk!
    # TODO: test for reqs
    if app_class_location == nil
      raise 
    end

    app_dir = app_class_location.split('/', -1)[0]
    build_gradle_dir = dir + '/build.gradle'
    build_gradle_app_dir = dir + '/' + app_dir + '/build.gradle'

    begin 
      content = File.read(build_gradle_dir)
    rescue
      puts "File not found: " + build_gradle_dir 
      puts "Provide first param project with directory path"
      return
    end

    begin 
      content = File.read(build_gradle_app_dir)
    rescue
      puts "Directory not found: " + dir + '/' + app_dir 
      puts "Provide second param Application file path directory. If no Appplication class available, OneSignal will create it at the directory provided."
      puts "Example: app/src/main/java/com/onesignal/testapplication/OneSignalApplication.java"
      return
    end

    application_class_created = false
    application_class_exists = true
    begin 
      content = File.read(dir + '/' + app_class_location)
    rescue
      directory_split = app_class_location.split('/', -1)

      application_name = directory_split[-1].split(".")[0]
      com_index = directory_split.index "com"
      range = directory_split.length - 2
      package_directory = directory_split.slice(com_index..range)
     
      puts "Application class will be created under #{dir}/#{app_class_location}\nThis is needed for SDK init code. By saying (N) you can setup the init code by following https://documentation.onesignal.com/docs/android-sdk-setup#step-3-add-required-code.\nProceed with creation? (Y/N)"
      user_response = STDIN.gets.chomp.downcase

      unless user_response == "y" || user_response == "yes" || user_response == "n" || user_response == "no"
        puts 'Invalid response (Y/N)'
        exit(1)
      end

      if user_response == "y" || user_response == "yes"
        create_application_file(package_directory, dir, app_dir, app_class_location, application_name, "#{self.lang}")
        application_class_created = true
      else
        application_class_exists = false
      end
    end 

    success_mesage = "*** OneSignal integration completed successfully! ***\n\n"
    gradle_plugin_mesage = " * Added repository provider gradlePluginPortal() to project build.gradle\n"
    os_gradle_plugin_mesage = " * Added dependency \"gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]\" to project build.gradle \n"
    app_os_gradle_plugin_mesage = " * Added plugin 'com.onesignal.androidsdk.onesignal-gradle-plugin' to app build.gradle\n"
    app_os_dependency_message = " * Added dependency 'com.onesignal:OneSignal:[4.0.0, 4.99.99]' to app build.gradle \n"

    # TODO: this gradle tack is a very brittle approach.
    # add deps to /build.gradle
    success_mesage += check_insert_lines(build_gradle_dir,
                  Regexp.quote("mavenCentral()"),
                  "gradlePluginPortal()",
                  gradle_plugin_mesage)

    success_mesage += check_insert_lines(build_gradle_dir,
                  Regexp.quote("jcenter()"),
                  "gradlePluginPortal()",
                  gradle_plugin_mesage)

    success_mesage += check_insert_lines(build_gradle_dir,
                  "classpath 'com.android.tools.build:gradle:[^']*'",
                  "classpath 'gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]'",
                  os_gradle_plugin_mesage)

    success_mesage += check_insert_lines(build_gradle_dir,
                  "classpath \"com.android.tools.build:gradle:[^']*\"",
                  "classpath \"gradle.plugin.com.onesignal:onesignal-gradle-plugin:[0.12.9, 0.99.99]\"",
                  os_gradle_plugin_mesage)

    # add deps to /app/build.gradle
    success_mesage += check_insert_lines(build_gradle_app_dir,
                  "implementation \"androidx.appcompat:appcompat:[^']*\"",
                  "implementation \"com.onesignal:OneSignal:[4.0.0, 4.99.99]\"",
                  app_os_dependency_message)

    success_mesage += check_insert_lines(build_gradle_app_dir,
                  "implementation 'androidx.appcompat:appcompat:[^']*'",
                  "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'",
                  app_os_dependency_message)

    success_mesage += check_insert_lines(build_gradle_app_dir,
                  "implementation \"com.google.android.material:material:[^']*\"",
                  "implementation \"com.onesignal:OneSignal:[4.0.0, 4.99.99]\"",
                  app_os_dependency_message)

    success_mesage += check_insert_lines(build_gradle_app_dir,
                  "implementation 'com.google.android.material:material:[^']*'",
                  "implementation 'com.onesignal:OneSignal:[4.0.0, 4.99.99]'",
                  app_os_dependency_message)

    success_mesage += check_insert_lines(build_gradle_app_dir,
                  "apply plugin: 'com.android.application'",
                  "apply plugin: 'com.onesignal.androidsdk.onesignal-gradle-plugin'",
                  app_os_gradle_plugin_mesage)

    success_mesage += check_insert_lines(build_gradle_app_dir,
                  "id 'com.android.application'",
                  "id 'com.onesignal.androidsdk.onesignal-gradle-plugin'",
                  app_os_gradle_plugin_mesage)

    if application_class_exists
      success_mesage += add_application_init_code(dir, app_class_location, lang)
    end

    if application_class_created
      success_mesage += " * Created " + application_name + " Application class at " + dir + '/' + app_class_location + "\n"
      success_mesage += " * Added Application class to AndroidManifest file\n"
    end


    if success_mesage == "*** OneSignal integration completed successfully! ***\n\n"
      puts "*** OneSignal already integrated, no changes needed ***\n\n"
    else
      puts success_mesage
    end
  end

  def check_insert_lines(directory, regex, addition, success_mesage = "")
    if !File.readlines(directory).any?{ |l| l[addition] }
      result = _insert_lines(directory, regex, addition)
      if (result.nil?)
        return ""
      end
      return success_mesage
    end
    return ""
  end

  def check_insert_block(directory, regex, addition, addition_block, success_mesage = "")
    if !File.readlines(directory).any?{ |l| l[addition] }
      _insert_lines(directory, regex, addition_block)
      return success_mesage
    end
    return ""
  end

  def create_application_file(package_directory, dir, app_dir, app_class_location, application_name, lang)
    File.open(dir + '/' + app_class_location, "w") do |f| 
      if lang == "java"    
        f.write("package #{package_directory.join(".")};\n\n")
        f.write("import android.app.Application;\n\n")
        f.write("public class #{application_name} extends Application {\n")
        f.write("\t@Override\n")
        f.write("\tpublic void onCreate() {\n")
        f.write("\t\tsuper.onCreate();\n")
        f.write("\t}\n")
        f.write("}")
      elsif lang == "kt"
        f.write("package #{package_directory.join(".")}\n\n")
        f.write("import android.app.Application\n\n")
        f.write("class #{application_name} : Application() {\n")
        f.write("\toverride fun onCreate() {\n")
        f.write("\t\tsuper.onCreate()\n")
        f.write("\t}\n")
        f.write("}")
      end
    end

    _insert_lines(dir + '/' + app_dir + '/src/main/AndroidManifest.xml',
              "<application",
              "\s\sandroid:name=\".#{application_name}\"")
  end

  def add_application_init_code(dir, app_class_location, lang)
    success_mesage = ""
    # add OS API key to Application class
    if lang == "java"
      success_mesage = check_insert_lines(dir + '/' + app_class_location,
                "import [a-zA-Z.]+;",
                "import com.onesignal.OneSignal;",
                " * OneSignal init method configured inside Application's onCreate method\n")
      check_insert_lines(dir + '/' + app_class_location,
                "public class [a-zA-Z\s]+{",
                "\tprivate static final String ONESIGNAL_APP_ID = \"" + self.os_app_id + "\";\n")
      check_insert_block(dir + '/' + app_class_location,
                /super.onCreate\(\);\s/,
                "OneSignal.setAppId",
        "// Enable verbose OneSignal logging to debug issues if needed.
        // It is recommended you remove this after validating your implementation.
        OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE);
        // OneSignal Initialization
        OneSignal.initWithContext(this);
        OneSignal.setAppId(ONESIGNAL_APP_ID);\n")
    elsif lang == "kt"
      success_mesage = check_insert_lines(dir + '/' + app_class_location,
                "import [a-zA-Z.]+",
                'import com.onesignal.OneSignal',
                " * OneSignal init method configured inside Application's onCreate method\n")
      check_insert_lines(dir + '/' + app_class_location,
                "class [a-zA-Z\s:()]+{",
                "\tprivate val oneSignalAppId = \"" + self.os_app_id + "\"\n")
      check_insert_block(dir + '/' + app_class_location,
                  /super.onCreate\(\)\s/,
                  "OneSignal.setAppId",
        "// Enable verbose OneSignal logging to debug issues if needed.
        // It is recommended you remove this after validating your implementation.
        OneSignal.setLogLevel(OneSignal.LOG_LEVEL.VERBOSE, OneSignal.LOG_LEVEL.NONE)
        // OneSignal Initialization
        OneSignal.initWithContext(this)
        OneSignal.setAppId(oneSignalAppId)\n")
    else 
      raise "Don't know to handle #{lang}"
    end
    return success_mesage
  end

  def has_sdk?
    # TODO: more robust testing
    return File.readlines(dir + '/app/build.gradle').grep(/OneSignal/).any?
  end
end

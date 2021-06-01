require 'clamp'
require_relative 'osproject'
require_relative 'osproject_ios'
require_relative 'osproject_android'

class AddCommand < Clamp::Command
    option "--type", "TYPE", "project type (osx, android)", default: "osx"
    parameter "PATH", "path to the project directory", default: "."
    parameter "TARGETNAME", "Name of the target XCProject or appclassfile", default: ""
    parameter "[LANG]", "language", default: "objc"
    parameter "[APPID]", "OneSignal App ID", default: ""

    def execute  
      langmap = {
        'objc' => :objc,
        'swift' => :swift,
        'java' => :java,
        'kotlin' => :kotlin
      }
      if type == 'osx'
        ios_proj = OSProject::IOS.new(dir, targetname, langmap[lang], appid)
        xcodeproj_path = dir + '/' + targetname + '.xcodeproj'
        ios_proj.install_onesignal!(xcodeproj_path)
      elsif type == 'android'
        OSProject::GoogleAndroid.new(dir, lang, appid).add_sdk!()
      else
        puts 'Invalid type (osx or android)'
      end
      
    end
end

class MooCommand < Clamp::Command
    def execute
      puts <<~COW
         _____________________
        < Moooooooooooooooooo >
         ---------------------
                \\   ^__^
                 \\  (oo)\\_______
                    (__)\\       )\\/\\
                        ||----w |
                        ||     ||
      COW
    end
end

class OSCLI < Clamp::Command
    subcommand "add_sdk", "Add the OneSignal SDK to the project", AddCommand,
    subcommand "moo", "introduces you to a helpful cow", MooCommand
end

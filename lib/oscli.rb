require 'clamp'
require_relative 'osproject'
require_relative 'osproject_ios'
require_relative 'osproject_android'

class AddCommand < Clamp::Command
    option [ "-t", "--type"], "TYPE", "project type (osx, android)"
    parameter "PATH", "path to the project directory"
    parameter "TARGETNAME", "Name of the target XCProject (osx) or appclassfile (android)"
    parameter "LANG", "programming language to use"
    parameter "[APPID]", "OneSignal App ID", default: ""

    def execute  
      langmap = {
        'objc' => :objc,
        'swift' => :swift,
        'java' => :java,
        'kotlin' => :kotlin
      }
      if type == 'osx'
        ios_proj = OSProject::IOS.new(path, targetname, langmap[lang], appid)
        xcodeproj_path = path + '/' + targetname + '.xcodeproj'
        ios_proj.install_onesignal!(xcodeproj_path)
      elsif type == 'android'
        OSProject::GoogleAndroid.new(path, lang, appid).add_sdk!()
      elsif !type
        puts 'Please provide a project type (osx or android) with the --type option'
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

class HelpCommand < Clamp::Command
  def execute
    OSCLI.helptext
  end
end

class OSCLI < Clamp::Command
    option ["--version", "-v"], :flag, "Show version" do
      puts "0.0.0"
      exit(0)
    end
    option ["--help", "-h"], :flag, "Show Commands" do
      OSCLI.helptext
      exit(0)
    end
    self.default_subcommand = "help"
    subcommand "help", "Lists the available commands in the OneSignal CLI", HelpCommand
    subcommand "add_sdk", "Add the OneSignal SDK to the project", AddCommand
    subcommand "moo", "introduces you to a helpful cow", MooCommand

    def self.helptext
      puts <<~HELP 
        add_sdk: Install the OneSignal SDK in the project
        moo: Introduces you to a helpful cow
        help: Lists the available commands in the OneSignal CLI
      HELP
    end
end

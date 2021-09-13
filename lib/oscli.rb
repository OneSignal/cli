require 'clamp'
require_relative 'osproject'
require_relative 'osproject_ios'
require_relative 'osproject_android'

class InstallCommand < Clamp::Command
    option [ "-t", "--type"], "TYPE", "project type (ios, android)"
    option ["--target"], "TARGETNAME", "name of the App target to use. Defaults to the entrypoint name"
    parameter "PATH", "path to the project directory"
    parameter "ENTRYPOINT", "Name of the target XCProject (ios) or appclassfile (android)"
    parameter "LANG", "programming language to use for ios (objc, swift) or android (java, kotlin)"
    parameter "[APPID]", "OneSignal App ID", default: ""

    def execute  
      langmap = {
        'objc' => :objc,
        'swift' => :swift,
        'java' => :java,
        'kotlin' => :kotlin
      }
      language = langmap[lang]

      if type == 'ios'
        unless language == :objc || language == :swift
          puts 'Invalid language (objc or swift)'
          exit(1)
        end
        if !target
          target = entrypoint
        end
        ios_proj = OSProject::IOS.new(path, target, language, appid)
        xcodeproj_path = path + '/' + entrypoint + '.xcodeproj'
        ios_proj.install_onesignal!(xcodeproj_path)
      elsif type == 'android'
        unless language == :java || language == :kotlin
          puts 'Invalid language (java or kotlin)'
          exit(1)
        end
        OSProject::GoogleAndroid.new(path, entrypoint, language, appid).add_sdk!()
      elsif !type
        puts 'Please provide a project type (ios or android) with the --type option'
      else
        puts 'Invalid type (ios or android)'
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
    subcommand "install-sdk", "Add the OneSignal SDK to the project", InstallCommand

    def self.helptext
      puts <<~HELP 
        \e[1mAvailable Commands:\e[0m 
        \e[1minstall-sdk:\e[0m  Install the OneSignal SDK in the project
        \e[1mhelp:\e[0m  Lists the available commands in the OneSignal CLI
        See: <command-name> --help for details
      HELP
    end
end

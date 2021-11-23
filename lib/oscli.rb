require 'clamp'
require_relative 'osproject'
require_relative 'osproject_ios'
require_relative 'osproject_android'
require 'net/http'
require 'uri'
require 'resolv-replace'

class InstallCommand < Clamp::Command
    option [ "-t", "--type"], "TYPE", "project type (ios, android)"
    option ["--target"], "TARGETNAME", "name of the App target to use. Defaults to the entrypoint name"
    option ["--path"], "PATH", "path to the project directory"
    option ["--entrypoint"], "ENTRYPOINT", "Name of the target XCProject (ios) or appclassfile (android)"
    option ["--lang"], "LANG", "programming language to use for ios (objc, swift) or android (java, kotlin)", default: ""
    option ["--appid"], "[APPID]", "OneSignal App ID"

    def execute  
      if appid.nil? || appid.empty?
        puts 'Please provide a project appId with the --appid option'
        exit(1)
      end
      
      if !type
        puts 'Please provide a project type (ios or android) with the --type option'
        exit(1)
      end

      type_downcase = type.downcase
      if type_downcase == 'ios'
        langmap = {
          'objc' => :objc,
          'swift' => :swift
        }
        language = langmap[lang]

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
      elsif type_downcase == 'android'
        OSProject::GoogleAndroid.new(entrypoint, appid).add_sdk!()
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

class AvailableCommandsCommand < Clamp::Command
  def execute
    OSCLI.availableCommandsText
  end
end

class OSCLI < Clamp::Command
    option ["--version", "-v"], :flag, "Show version" do
      puts OSProject.version
      NetworkHandler.instance.send_track_command("--version")
      exit(0)
    end
    option ["--help", "-h"], :flag, "Show Commands" do
      OSCLI.helptext
      exit(0)
    end
    self.default_subcommand = "available-commands"
    subcommand "available-commands", "Lists the available commands in the OneSignal CLI", AvailableCommandsCommand
    subcommand "help", "Lists the available commands in the OneSignal CLI", HelpCommand
    subcommand "install-sdk", "Add the OneSignal SDK to the project", InstallCommand

    def self.helptext
      puts "usage: bin/onesignal [--version] [--help] [install-sdk --type <type> <path> <entrypoint> <lang> <appId>]"
      NetworkHandler.instance.send_track_command("--help")
    end

    def self.availableCommandsText
      puts <<~HELP 
        \e[1mAvailable Commands:\e[0m 
        \e[1minstall-sdk:\e[0m  Install the OneSignal SDK in the project
        \e[1mhelp:\e[0m  Lists the available commands in the OneSignal CLI
        See: <command-name> --help for details
      HELP
      NetworkHandler.instance.send_track_command("available-commands")
    end
end

require 'clamp'
require_relative 'osproject'

class AddCommand < Clamp::Command
    option "--type", "TYPE", "project type (osx, android)", default: "osx"
    parameter "[DIR]", "project directory", default: "."
    
    def execute
      OSProject.new(type, dir).add_sdk()
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
    subcommand "add", "Add the OneSignal SDK to the project", AddCommand
    subcommand "moo", "introduces you to a helpful cow", MooCommand
end

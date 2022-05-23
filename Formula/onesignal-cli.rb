class OnesignalCli < Formula
  desc "The OneSignal CLI is a tool to work with OneSignal projects."
  homepage "https://github.com/OneSignal/cli"
  url "https://github.com/OneSignal/cli.git", tag: "gemspec-test", revision: "e39a9c2d4c02633f6a23465ad0037ff98e180653"
  license "MIT"
  version "gemspec-test"

    def install
      prefix.install 'Gemfile'
      include.install Dir["include/*"]
      lib.install Dir["lib/*"]
      bin.install Dir["bin/*"]
    end
  
    def postinstall
      
    end
    test do
      version_output = shell_output("#{bin}/onesignal version 2>&1")
      assert_match("cli  Version: #{version}", version_output)
    end
  end
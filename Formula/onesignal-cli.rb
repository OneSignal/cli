class OnesignalCli < Formula
    desc "The OneSignal CLI is a tool to work with OneSignal projects."
    homepage "https://github.com/OneSignal/cli"
    url "https://github.com/OneSignal/cli/archive/refs/tags/0.0.4.tar.gz"
    sha256 "a1f57cbab45a3322fd29a5dbbd3350fa30169c6338ec566af9c9b802dc45cef2"
    license "MIT"
    version "0.0.4"

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
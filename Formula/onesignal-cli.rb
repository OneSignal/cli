class OnesignalCli < Formula
    desc "The OneSignal CLI is a tool to work with OneSignal projects."
    homepage "https://github.com/OneSignal/cli"
    url "https://github.com/OneSignal/cli/archive/refs/tags/v0.0.1.tar.gz"
    sha256 "32bf3183804b4c823669eabd426da0f5fb69f7130e8fae2baeba14665420e964"
    license "MIT"
    version "0.0.1"

    def install
      lib.install Dir["lib/*"]
      
      bin.install Dir["bin/*"]
    end
  
    test do
      version_output = shell_output("#{bin}/onesignal version 2>&1")
      assert_match("cli  Version: #{version}", version_output)
    end
  end
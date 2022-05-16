class OnesignalCli < Formula
    desc "The OneSignal CLI is a tool to work with OneSignal projects."
    homepage "https://github.com/OneSignal/onesignal-cli"
    url "https://github.com/OneSignal/onesignal-cli/archive/refs/tags/0.0.4.tar.gz"
    sha256 "b74df2f09481f93f7e8240c2e348c653b4f5d2c8383d912b30e0cffb883b66d6"
    license "MIT"
    version "0.0.4"

    def install
      prefix.install 'Gemfile'
      include.install Dir["include/*"]
      lib.install Dir["lib/*"]
      bin.install Dir["bin/*"]
    end
  
    def postinstall
      bin.install Dir["bin/*"]
    end
    test do
      version_output = shell_output("#{bin}/onesignal version 2>&1")
      assert_match("cli  Version: #{version}", version_output)
    end
  end
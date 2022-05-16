class OnesignalCli < Formula
    desc "The OneSignal CLI is a tool to work with OneSignal projects."
    homepage "https://github.com/OneSignal/cli"
    url "https://github.com/OneSignal/cli/archive/refs/tags/0.0.4.tar.gz"
    sha256 "b1c4a0ec7a4c5781c823578cd75302db61fcc10e6f46c88805777bcc84323a94"
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
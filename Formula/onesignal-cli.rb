class OnesignalCli < Formula
    desc "The OneSignal CLI is a tool to work with OneSignal projects."
    homepage "https://github.com/OneSignal/cli"
    url "https://github.com/OneSignal/cli/archive/refs/tags/0.0.2.tar.gz"
    sha256 "8b711a13448c29c8a4a42b846684fb7d44fd751612323a0f8cb1fe36b6d4f5f0"
    license "MIT"
    version "0.0.2"

    depends_on 'bash' => :run

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
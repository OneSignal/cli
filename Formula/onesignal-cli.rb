class OnesignalCli < Formula
    desc "The OneSignal CLI is a tool to work with OneSignal projects."
    homepage "https://github.com/OneSignal/cli"
    # url "https://github.com/OneSignal/cli/archive/refs/tags/install-test.tar.gz"
    url "file:///Users/josh/Documents/repos/cli.tar.gz"
    # sha256 "102cab6438af575932dc9e8c81e5198c3d499754ff4c5f39f1e78da685002c43"
    license "MIT"
    version "install-test"

    depends_on "ruby" if Hardware::CPU.arm?
    uses_from_macos "ruby", since: :catalina

    def install
      # prefix.install 'Gemfile'
      # prefix.install 'onesignal-cli.gemspec'
      if MacOS.version >= :mojave && MacOS::CLT.installed?
        ENV["SDKROOT"] = ENV["HOMEBREW_SDKROOT"] = MacOS::CLT.sdk_path(MacOS.version)
      end
  
      ENV["GEM_HOME"] = libexec

      system "gem", "build", "onesignal-cli.gemspec"
      system "gem", "install", "onesignal-cli-1.0.0.gem"

      bin.install libexec/"bin/onesignal"
      bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
    end
  
    # def post_install
    #   bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
    #   #system "#{bin}/onesignal_postinstall"
    #   ENV["GEM_HOME"] = libexec
    #   # system "gem", "install", "bundler", "--user-install"
    #   system "bundle", "install"
    #   #system "gem", "install", "bundler"
    #   #system "bundle", "install"
    #   #system "gem", "install", "bundler", "--conservative"
    #   #system "#{bin}/bundle", "install"
      
    # end
    test do
      version_output = shell_output("#{bin}/onesignal version 2>&1")
      assert_match("cli  Version: #{version}", version_output)
    end
  end
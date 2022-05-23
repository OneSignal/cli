class OnesignalCli < Formula
  desc "The OneSignal CLI is a tool to work with OneSignal projects."
  homepage "https://github.com/OneSignal/cli"
  url "https://github.com/OneSignal/cli/archive/refs/tags/gemspec-test.tar.gz"
  sha256 "25d0354a2c4237034eaa736c8ccdefb324b39dd4620e08f257c059273e5487e2"
  license "MIT"
  version "gemspec-test"

  depends_on "ruby" if Hardware::CPU.arm?
  uses_from_macos "ruby", since: :catalina

  def install
    if MacOS.version >= :mojave && MacOS::CLT.installed?
      ENV["SDKROOT"] = ENV["HOMEBREW_SDKROOT"] = MacOS::CLT.sdk_path(MacOS.version)
    end

    ENV["GEM_HOME"] = libexec

    system "gem", "build", "onesignal-cli.gemspec"
    system "gem", "install", "onesignal-cli-1.0.0.gem"

    bin.install libexec/"bin/onesignal"
    # onesignal executable is now run from the libexec/bin folder
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    version_output = shell_output("#{bin}/onesignal version 2>&1")
    assert_match("cli  Version: #{version}", version_output)
  end
end
class OnesignalCli < Formula
  desc "The OneSignal CLI is a tool to work with OneSignal projects."
  homepage "https://github.com/OneSignal/cli"
  url "https://github.com/OneSignal/cli.git", tag: "0.0.7", revision: "319c2def60a37e60935c8c982295c6a86883025b"
  license "MIT"
  version "0.0.7"

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
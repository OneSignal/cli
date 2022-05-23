import sys

def update_version(version):
  formula = open('Formula/onesignal-cli.rb', 'r')
  lines = formula.readlines()
  lines[3] = "  url \"https://github.com/OneSignal/cli/archive/refs/tags/{}.tar.gz\"\n".format(version)
  lines[6] = "  version \"{}\"\n".format(version)

  formula = open('Formula/onesignal-cli.rb', 'w')
  formula.writelines(lines)
  formula.close()

def update_checksum(checksum):
  formula = open('Formula/onesignal-cli.rb', 'r')
  lines = formula.readlines()
  lines[4] = "  sha256 \"{}\"\n".format(checksum)

  formula = open('Formula/onesignal-cli.rb', 'w')
  formula.writelines(lines)
  formula.close()

newReleaseVersion = str(sys.argv[1])
newChecksum = str(sys.argv[2])
update_version(newReleaseVersion)
update_checksum(newChecksum)
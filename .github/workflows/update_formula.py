import sys

def update_version(version, revision):
  formula = open('Formula/onesignal-cli.rb', 'r')
  lines = formula.readlines()
  lines[3] = "  url \"https://github.com/OneSignal/cli.git\", tag: \"{}\", revision: \"{}\"\n".format(version, revision)

  formula = open('Formula/onesignal-cli.rb', 'w')
  formula.writelines(lines)
  formula.close()

newReleaseVersion = str(sys.argv[1])
newRevision = str(sys.argv[2])
update_version(newReleaseVersion, newRevision)
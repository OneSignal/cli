# OneSignal CLI

### :warning: This tool is currently in Beta :warning:

The OneSignal CLI is a tool to work with OneSignal projects.

# Setup
1. Clone the repository
2. If you do not have bundler 2 installed run `gem install bundler`
3. Run `bundle install` from the root directory of the repository
4. Commands can be run via `bin/onesignal <command>` from the root of the repository

## Installation Command
This command can be used to add the OneSignal SDK to your mobile application project.
Currently only supports iOS Native SDK install.
For iOS the command will: 
* add push notification capabilities and background modes
* Add the OneSignal cocoapod or Swift Package
* create and setup a Notification Service Extension
* setup an App Group for communication with the NSE.

It does not yet add OneSignal initialization code in AppDelegate with your App ID.

Options:
* type - iOS or Android. Type of SDK to install. Required.
* target - name of the App target to install in. Defaults to the entrypoint name. iOS only.

Arguments:
* Path - path to the project directory
* Entrypoint - Name of the target XCProject (iOS) or appclassfile (Android)
* LANG - programming language to use for ios (objc, swift) or Android (java, kotlin)
* APPID - Optional. OneSignal App ID. Not yet used for iOS installs.

Example Usage
`install-sdk --type ios ../MyAppDir MyApp objc`

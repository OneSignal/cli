# OneSignal CLI

The OneSignal CLI is a tool to work with OneSignal projects.

## Testing
Clone the repo and test via `bin/onesignal`.

## Installation Command
This command can be used to add the OneSignal SDK to your mobile application project.
Currently only supports iOS Native SDK install.
For OSX the command will: 
* add push notification capabilities and background modes
* Add the OneSignal cocoapod or Swift Package
* create and setup a Notification Service Extension
* setup an App Group for communication with the NSE.

It does not yet add OneSignal initialization code in AppDelegate with your App ID.

Options:
* type - OSX or Android. Type of SDK to install. Required.
* target - name of the App target to install in. Defaults to the entrypoint name. OSX only.

Arguments:
* Path - path to the project directory
* Entrypoint - Name of the target XCProject (osx) or appclassfile (Android)
* LANG - programming language to use for osx (objc, swift) or Android (java, kotlin)
* APPID - Optional. OneSignal App ID. Not yet used for OSX installs.

Example Usage
`install-sdk --type osx ../MyAppDir MyApp objc`

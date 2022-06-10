# Architecture
The CLI is implemented using the Clamp framework.

Controller logic for CLI commands are located in `lib/oscli.rb`.  Business logic around project source code bases is located in `lib/osproject.rb` and defined in `lib/osproject_android.rb` and `lib/osproject_ios.rb`.  `lib/osproject_helpers.rb` contains a suite of file manipulation functions used by OSProject subclasses.

# Testing

## SDK
Test cases are organized under `spec/samples`.  They are organized first by platform, then language, then
projectname.  For example, `spec/samples/googleandroid/kotlin/bottomnav`.

The primary tests are located in `spec/osproject_spec.rb`, which contains the autoloading platform test.  Additional SDK sample tests are defined in this file.

Using RSpec, you can run test cases using `bin/rspec spec/osproject_spec.rb`. Note that the require paths are resolved according to the dir you're in when you're executing the code so running `bin/rspec spec/osproject_spec.rb` from inside the spec folder will not work.

## CLI
CLI Behavior and business logic tests are located in `spec/osproject_spec.rb`.

## API
API calls are not tested, as the API Client Library codebase handles this.

# Building
Deliverable build process is undefined.  Test via `bin/onesignal`.

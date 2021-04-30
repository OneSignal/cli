require_relative 'osproject'
require 'xcodeproj'

class OSProject::IOS < OSProject
  # this is a temporary placeholder
  attr_accessor :has_sdk

  def initialize(dir, lang, os_app_id)
    @has_sdk = false
    super(:ios, dir, lang, os_app_id)
  end
  def add_sdk!
    @has_sdk = true
  end
  def has_sdk?
    return self.has_sdk
  end

  def install_onesignal(xcproj_path, target_name, os_app_id)

  end

  # create new target
  # needs notificationservice files, plists
  # set bundle id, dev team?
  # embed in main app target
  # can be done using xcodeproj
  def create_nse()
  end

  # add OneSignalXCFramework Swift Package dependency
  # can use xcoed gem for this
  def add_onesignal_sp_dependency()
  end

  # add swift package binary to nse target
  # can use xcoed gem for this
  def add_onesignal_framework_to_nse()
  end 

  # app groups capability
  # use xcodeproj
  def add_app_groups_to_nse()
  end

  # Code is dependent on language but otherwise a constant
  # Probably should just be a file with code already populated.
  def add_onesignal_code_to_nse()
  end

  # add swift package binary to main target
  # can use xcoed gem for this
  def add_onesignal_framework_to_main_target()
  end 

  # push capability in entitlments
  # background capability with remote notifications enabled
  # use xcodeproj
  def add_capabilities_to_main_target()
  end

  # app groups capability
  # use xcodeproj
  def add_app_groups_to_main_target()
  end

  # depends on language and app lifecycle (appdelegate vs swiftui)
  def add_os_init_to_app_target()
  end 

end


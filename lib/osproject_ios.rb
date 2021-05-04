require_relative 'osproject'
require 'xcodeproj'

class OSProject::IOS < OSProject
  # this is a temporary placeholder
  attr_accessor :has_sdk 

  attr_accessor :project 
  attr_accessor :target 
  attr_accessor :nse 

  attr_accessor :target_name

  def initialize(dir, lang, os_app_id)
    @has_sdk = false
    super("ios", dir, lang, os_app_id)
  end

  def _add_sdk
    @has_sdk = true
    _add_onesignal_dependency()
    #Main target setup
    _add_onesignal_framework_to_main_target()
    _add_capabilities_to_main_target()
    _add_app_groups_to_main_target()
    _add_os_init_to_app_target()
    #NSE setup
    _create_nse()
    _add_onesignal_framework_to_nse()
    _add_app_groups_to_nse()
  end

  def has_sdk?
    return self.has_sdk
  end

  def install_onesignal!(xcproj_path, target_name)
    # TODO error check too make sure both project and target were found
    @project = Xcodeproj::Project.open(xcproj_path)
    @target = self.project.native_targets.find { |target| target.name == target_name}
    # this can be used to get the entitlements plist
    @target_name = target_name
    # TODO get dev team and bundle id for the target

    _add_sdk()
  end

  #Just SPM for now. Can be extended to support Cocoapods
  def _add_onesignal_dependency()
    _add_onesignal_sp_dependency()
  end

  # create new target
  # needs notificationservice files, plists
  # set bundle id, dev team?
  # embed in main app target
  # can be done using xcodeproj
  def _create_nse()
    
    group = self.project.main_group.find_subpath('OneSignalNotificationServiceExtension', true)
    # This should just be a file we add with the code already in it.
    nsePath = self.dir + '/OneSignalNotificationServiceExtension'
    unless File.directory?(nsePath)
      FileUtils.mkdir(nsePath)
    end

    if lang == :swift
      FileUtils.cp_r('lib/NotificationService.swift', nsePath) 
      assets = group.new_reference("OneSignalNotificationServiceExtension/NotificationService.swift")
    else
      FileUtils.cp_r %w(lib/NotificationService.h lib/NotificationService.m), nsePath
      group.new_reference("OneSignalNotificationServiceExtension/NotificationService.h")
      assets = group.new_reference("OneSignalNotificationServiceExtension/NotificationService.m")
    end

    # copy the Info.plist file into the NSE group
    FileUtils.cp_r('lib/Info.plist', nsePath)
    plist_reference = group.new_reference("OneSignalNotificationServiceExtension/Info.plist")

    # Create NSE target
    @nse = self.project.new_target(:app_extension, 'OneSignalNotificationServiceExtension', :ios, "10.0", nil, lang)
    self.nse.add_file_references([assets])

    # Set Info.plist and Product Name
    self.nse.build_configuration_list.set_setting('INFOPLIST_FILE', 'OneSignalNotificationServiceExtension/Info.plist')
    self.nse.build_configuration_list.set_setting('PRODUCT_NAME', 'OneSignalNotificationServiceExtension')
    # Set bundle id based on @target's Debug bundle id
    bundle_id = self.target.build_configuration_list.get_setting('PRODUCT_BUNDLE_IDENTIFIER')["Debug"]
    self.nse.build_configuration_list.set_setting('PRODUCT_BUNDLE_IDENTIFIER', bundle_id + ".OneSignalNotificationServiceExtension")
    # Set dev team based on @target's dev team
    dev_team = self.target.build_configuration_list.get_setting('DEVELOPMENT_TEAM')["Debug"]
    self.nse.build_configuration_list.set_setting('DEVELOPMENT_TEAM', dev_team)
    
    _add_nse_to_app_target()

    self.project.save()
  end

  def _add_nse_to_app_target()
    self.target.add_dependency(self.nse)
    nse_product = self.nse.product_reference
    puts self.target.copy_files_build_phases 
    embed_extensions_phase = self.target.copy_files_build_phases.find do |copy_phase|
      copy_phase.symbol_dst_subfolder_spec == :plug_ins
    end
    if embed_extensions_phase.nil?
      embed_extensions_phase = self.target.new_copy_files_build_phase('Embed App Extensions')
    end
    abort "Couldn't find 'Embed App Extensions' phase" if embed_extensions_phase.nil?

    build_file = embed_extensions_phase.add_file_reference(nse_product)
    build_file.settings = { "ATTRIBUTES" => ['RemoveHeadersOnCopy'] }
    self.project.save()
  end

  # add OneSignalXCFramework Swift Package dependency
  # can use xcoed gem for this
  def _add_onesignal_sp_dependency()
  end

  # add swift package binary to nse target
  # can use xcoed gem for this
  def _add_onesignal_framework_to_nse()
  end 

  # app groups capability
  # use xcodeproj
  def _add_app_groups_to_nse()
  end

  # Code is dependent on language but otherwise a constant
  # Probably should just be a file with code already populated.
  def _add_onesignal_code_to_nse()
  end

  # add swift package binary to main target
  # can use xcoed gem for this
  def _add_onesignal_framework_to_main_target()
  end 

  # push capability in entitlments
  # background capability with remote notifications enabled
  # use xcodeproj
  def _add_capabilities_to_main_target()
  end

  # app groups capability
  # use xcodeproj
  def _add_app_groups_to_main_target()
  end

  # depends on language and app lifecycle (appdelegate vs swiftui)
  def _add_os_init_to_app_target()
  end 

end


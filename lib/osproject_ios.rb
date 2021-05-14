require_relative 'osproject'
require 'xcodeproj'

class OSProject::IOS < OSProject
  # this is a temporary placeholder
  attr_accessor :has_sdk 

  attr_accessor :project 
  attr_accessor :target 
  attr_accessor :nse 
  attr_accessor :nse_group
  attr_accessor :onesignal_ref
  attr_accessor :onesignal_product_ref

  attr_accessor :target_name

  SWIFT_NSE_PATH = 'tmpl/iOS/swift/NotificationService.swift'
  OBJC_NSE_H_PATH = 'tmpl/iOS/objc/NotificationService.h'
  OBJC_NSE_M_PATH = 'tmpl/iOS/objc/NotificationService.m'
  NSE_INFO_PLIST_PATH = 'tmpl/iOS/Info.plist'

  def initialize(dir, lang, os_app_id)
    @has_sdk = false
    super("ios", dir, lang, os_app_id)
  end

  def _add_sdk
    @has_sdk = true
    # Order matters here
    _add_onesignal_dependency()
    #Main target setup
    _add_onesignal_framework_to_main_target()
    _add_capabilities_to_main_target()
    _add_os_init_to_app_target()
    #NSE setup
    _create_nse()
    _add_nse_to_app_target()
    _add_onesignal_framework_to_nse()
    _add_app_groups_to_nse()
  end

  def has_sdk?
    return self.has_sdk
  end

  # Called by oscli's add command
  def install_onesignal!(xcproj_path, target_name)
    # TODO error check too make sure both project and target were found
    @project = Xcodeproj::Project.open(xcproj_path)
    @target = self.project.native_targets.find { |target| target.name == target_name}
    @target_name = target_name

    _add_sdk()
  end

  #Just SPM for now. Can be extended to support Cocoapods
  def _add_onesignal_dependency()
    _add_onesignal_sp_dependency()
  end

  def _create_nse()
    
    @nse_group = self.project.main_group.find_subpath('OneSignalNotificationServiceExtension', true)
    # This should just be a file we add with the code already in it.
    nsePath = self.dir + '/OneSignalNotificationServiceExtension'
    unless File.directory?(nsePath)
      FileUtils.mkdir(nsePath)
    end

    if lang == :swift
      FileUtils.cp_r(SWIFT_NSE_PATH, nsePath) 
      assets = self.nse_group.new_reference("OneSignalNotificationServiceExtension/NotificationService.swift")
    else
      FileUtils.cp_r [OBJC_NSE_H_PATH, OBJC_NSE_M_PATH], nsePath
      self.nse_group.new_reference("OneSignalNotificationServiceExtension/NotificationService.h")
      assets = self.nse_group.new_reference("OneSignalNotificationServiceExtension/NotificationService.m")
    end

    # copy the Info.plist file into the NSE group
    FileUtils.cp_r(NSE_INFO_PLIST_PATH, nsePath)
    plist_reference = self.nse_group.new_reference("OneSignalNotificationServiceExtension/Info.plist")

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
  def _add_onesignal_sp_dependency()
    # Remove existing dependency if it exists
    self.project.root_object.package_references
           .select { |ref| ref.repositoryURL == 'https://github.com/OneSignal/OneSignal-XCFramework.git' }
           .each(&:remove_from_project)

    # Create new package reference
    package_ref = Xcodeproj::Project::Object::XCRemoteSwiftPackageReference.new(self.project, self.project.generate_uuid)
    package_ref.repositoryURL = 'https://github.com/OneSignal/OneSignal-XCFramework.git'
    package_ref.requirement = {
      'kind' => 'upToNextMajorVersion',
      'minimumVersion' => '3.4.3',
    }
    @onesignal_ref = package_ref
    self.project.root_object.package_references << self.onesignal_ref
    
    @onesignal_product_ref = Xcodeproj::Project::Object::XCSwiftPackageProductDependency.new(project, project.generate_uuid)
    self.onesignal_product_ref.product_name = 'OneSignal'
    self.project.save()
  end

  # add swift package binary to nse target
  def _add_onesignal_framework_to_nse()
    self.nse.package_product_dependencies
                 .select { |product| product.product_name == 'OneSignal' }
                 .each(&:remove_from_project)

    self.nse.package_product_dependencies << self.onesignal_product_ref
    self.project.save()
  end 

  # app groups capability
  # Creates OneSignalNotificationServiceExtension.entitlements if it doesn't exist
  def _add_app_groups_to_nse()
    group_relative_entitlements_path = self.nse.name + "/" + self.nse.name + ".entitlements"
    entitlements_path = dir + "/" + group_relative_entitlements_path
    entitlements = {}
    bundle_id = self.target.build_configuration_list.get_setting('PRODUCT_BUNDLE_IDENTIFIER')["Debug"]
    app_group_name = 'group.' + bundle_id + '.onesignal'
    if File.exist?(entitlements_path)
      entitlements = Xcodeproj::Plist.read_from_path(entitlements_path)
      if entitlements['com.apple.security.application-groups'].nil?
        entitlements['com.apple.security.application-groups'] = [app_group_name]
      elsif !entitlements['com.apple.security.application-groups'].include? app_group_name
        entitlements['com.apple.security.application-groups'].append(app_group_name)
      end
      Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
    else
      entitlements = {
        'com.apple.security.application-groups' => [app_group_name]
      }
      Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
      self.nse_group.new_reference(group_relative_entitlements_path)
      self.nse.build_configuration_list.set_setting('CODE_SIGN_ENTITLEMENTS', group_relative_entitlements_path)
    end
    self.project.save()
  end

  # add swift package binary to main target
  def _add_onesignal_framework_to_main_target()
    self.target.package_product_dependencies
                  .select { |product| product.product_name == 'OneSignal' }
                  .each(&:remove_from_project)

    self.target.package_product_dependencies << self.onesignal_product_ref
    self.project.save()
  end 

  # push capability in entitlments
  # background capability with remote notifications enabled
  # App group entitlement based on target bundle id
  def _add_capabilities_to_main_target()
    
    #Update Info.plist of Target to include background modes with remote notifications
    plist_path = dir + "/" + self.target.build_configuration_list.get_setting('INFOPLIST_FILE')['Debug']
    info_plist = Xcodeproj::Plist.read_from_path(plist_path)
    if info_plist["UIBackgroundModes"].nil?
      info_plist["UIBackgroundModes"] = ["remote-notification"]
    elsif !info_plist["UIBackgroundModes"].include? 'remote-notification'
      info_plist["UIBackgroundModes"].append('remote-notification')
    end

    Xcodeproj::Plist.write_to_path(info_plist, plist_path)

    #Create targetname.entitlements if it doesn't exist
    group = self.project.main_group.find_subpath(self.target_name, false)
    group_relative_entitlements_path = group.path + "/" + self.target_name + ".entitlements"
    entitlements_path = dir + "/" + group_relative_entitlements_path
    entitlements = {}
    if File.exist?(entitlements_path)
      entitlements = Xcodeproj::Plist.read_from_path(entitlements_path)
      if entitlements['aps-environment'].nil?
        entitlements['aps-environment'] = 'development'
        Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
      end
    else
      entitlements = {
        'aps-environment' => 'development'
      }
      Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
      group.new_reference(self.target_name + ".entitlements")
      self.target.build_configuration_list.set_setting('CODE_SIGN_ENTITLEMENTS', group_relative_entitlements_path)
    end

    # Add App Group to entitlements
    bundle_id = self.target.build_configuration_list.get_setting('PRODUCT_BUNDLE_IDENTIFIER')["Debug"]
    app_group_name = 'group.' + bundle_id + '.onesignal'
    if entitlements['com.apple.security.application-groups'].nil?
      entitlements['com.apple.security.application-groups'] = [app_group_name]
    elsif !entitlements['com.apple.security.application-groups'].include? app_group_name
      entitlements['com.apple.security.application-groups'].append(app_group_name)
    end
    Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
    self.project.save()
  end

  # depends on language and app lifecycle (appdelegate vs swiftui)
  def _add_os_init_to_app_target()
  end 

end


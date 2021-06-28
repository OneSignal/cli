require_relative 'osproject'
require_relative 'osproject_helpers'
require 'xcodeproj'

class OSProject::IOS < OSProject
  # this is a temporary placeholder

  attr_accessor :project 
  attr_accessor :target 
  attr_accessor :nse 
  attr_accessor :nse_group
  attr_accessor :onesignal_ref
  attr_accessor :onesignal_product_ref

  attr_accessor :target_name

  SWIFT_NSE_PATH = '/tmpl/iOS/swift/NotificationService.swift'
  OBJC_NSE_H_PATH = '/tmpl/iOS/objc/NotificationService.h'
  OBJC_NSE_M_PATH = '/tmpl/iOS/objc/NotificationService.m'
  NSE_INFO_PLIST_PATH = '/tmpl/iOS/Info.plist'

  NSE_POD_DEPENDENCY = "target 'OneSignalNotificationServiceExtension' do
  # Comment the next line if you don\'t want to use dynamic frameworks
  use_frameworks!

  # Pods for OneSignalNotificationServiceExtension
  pod 'OneSignalXCFramework', '>= 3.4.3', '< 4.0'

end"

  def initialize(dir, target_name, lang, os_app_id)
    @has_sdk = false
    @target_name = target_name
    super("iOS", dir, lang, os_app_id)
  end

  def _add_sdk
    # Order matters here
    #Main target setup
    _add_capabilities_to_main_target()
    _add_os_init_to_app_target()
    #NSE setup
    _create_nse()
    _add_nse_to_app_target()
    _add_app_groups_to_nse()
    #Add OneSignal
    _add_onesignal_dependency()
  end

  def has_sdk?
    unless !self.project 
      return self.project.root_object.package_references.any? { |ref| ref.repositoryURL == 'https://github.com/OneSignal/OneSignal-XCFramework.git' } ||
      File.open(self.dir + '/Podfile').each_line.any?{|line| line.include?("pod 'OneSignalXCFramework'") }
    end
    false
  end

  # Called by oscli's add command
  def install_onesignal!(xcproj_path)
    if File.exist?(xcproj_path)
      @project = Xcodeproj::Project.open(xcproj_path)
    else
      puts "Unable to open an xcodeproj at path: " + xcproj_path
      exit(1)
    end
    
    @target = self.project.native_targets.find { |target| target.name == self.target_name}
    if !self.target
      puts "Unable to find an app target with name: " + self.target_name
      exit(1)
    end
    
    _add_sdk()
    
    puts "Finished Installing OneSignal"
  end

  # Only use Cocoapods if a Podfile already exists. If not use SwiftPM
  def _add_onesignal_dependency()
    if File.exist?(self.dir + '/Podfile')
      _add_onesignal_podspec_dependency()
    else 
      _add_onesignal_sp_dependency()
      _add_onesignal_framework_to_main_target()
      _add_onesignal_framework_to_nse()
    end
  end

  def _add_onesignal_podspec_dependency()
    # remove Podfile.lock
    File.delete(self.dir + '/Podfile.lock') if File.exist?(self.dir + '/Podfile.lock')

    #Append OneSignal Pod to the main target unless it is already in the podfile
    unless File.open(self.dir + '/Podfile').each_line.any?{|line| line.include?("pod 'OneSignalXCFramework', '>= 3.4.3', '< 4.0'") }
      _insert_lines(self.dir + '/Podfile', 
        Regexp.quote("target '" + self.target_name + "' do"),
        "  pod 'OneSignalXCFramework', '>= 3.4.3', '< 4.0'")
    end
    
    #Append the NSE Target with OneSignal Pod unless the NSE target is already in the podfile
    unless File.open(self.dir + '/Podfile').each_line.any?{|line| line.include?("target 'OneSignalNotificationServiceExtension' do") }
      File.open(self.dir + '/Podfile', 'a') { |f| f.write(NSE_POD_DEPENDENCY) }
    end

    #Run pod install on the proj directory
    install_script = 'pod install --project-directory=' + self.dir
    success = system(install_script)
    if success
      puts "Installed OneSignal pod"
    else  
      puts "Error adding OneSignal to Podfile"
    end
  end

  def _create_nse()
    # Create NSE target
    self.project.embedded_targets_in_native_target(self.target).each do |embedded_target|
      return if embedded_target.name == 'OneSignalNotificationServiceExtension'
    end
    @nse = self.project.new_target(:app_extension, 'OneSignalNotificationServiceExtension', :ios, self.target.deployment_target, nil, lang)
    self.nse.build_configuration_list.set_setting('PRODUCT_NAME', 'OneSignalNotificationServiceExtension')
    # Set bundle id based on @target's Debug bundle id
    bundle_id = self.target.build_configuration_list.get_setting('PRODUCT_BUNDLE_IDENTIFIER')["Debug"]
    self.nse.build_configuration_list.set_setting('PRODUCT_BUNDLE_IDENTIFIER', bundle_id + ".OneSignalNotificationServiceExtension")
    # Set dev team based on @target's dev team
    dev_team = self.target.build_configuration_list.get_setting('DEVELOPMENT_TEAM')["Debug"]
    self.nse.build_configuration_list.set_setting('DEVELOPMENT_TEAM', dev_team)
    if lang == :swift
      self.nse.build_configuration_list.set_setting('SWIFT_VERSION', '5.0')
    end
    device_family = self.target.build_configuration_list.get_setting('TARGETED_DEVICE_FAMILY')["Debug"]
    self.nse.build_configuration_list.set_setting('LD_RUNPATH_SEARCH_PATHS', "$(inherited) @executable_path/Frameworks")
    self.nse.build_configuration_list.set_setting('TARGETED_DEVICE_FAMILY', device_family)

    @nse_group = self.project.main_group.find_subpath('OneSignalNotificationServiceExtension', true)
    # This should just be a file we add with the code already in it.
    nsePath = self.dir + '/OneSignalNotificationServiceExtension'
    unless File.directory?(nsePath)
      FileUtils.mkdir(nsePath)
    end
    cli_dir = File.expand_path(File.dirname(__dir__))
    if lang == :swift && !File.exist?(nsePath + '/NotificationService.swift')
      FileUtils.cp_r(cli_dir + SWIFT_NSE_PATH, nsePath) 
      self.nse.add_file_references([self.nse_group.new_reference("OneSignalNotificationServiceExtension/NotificationService.swift")])
    elsif lang == :objc && !File.exist?(nsePath + '/NotificationService.m')
      FileUtils.cp_r [cli_dir + OBJC_NSE_H_PATH, cli_dir + OBJC_NSE_M_PATH], nsePath
      self.nse_group.new_reference("OneSignalNotificationServiceExtension/NotificationService.h")
      self.nse.add_file_references([self.nse_group.new_reference("OneSignalNotificationServiceExtension/NotificationService.m")])
    end

    # copy the Info.plist file into the NSE group
    unless File.exist?(nsePath + '/Info.plist')
      FileUtils.cp_r(cli_dir + NSE_INFO_PLIST_PATH, nsePath)
      self.nse_group.new_reference("OneSignalNotificationServiceExtension/Info.plist")
      self.nse.build_configuration_list.set_setting('INFOPLIST_FILE', 'OneSignalNotificationServiceExtension/Info.plist')
    end
    puts "Created OneSignalNotificationServiceExtension"
    self.project.save()
  end

  def _add_nse_to_app_target()
    return if !self.nse
    unless self.target.dependency_for_target(self.nse)
      self.target.add_dependency(self.nse)
      nse_product = self.nse.product_reference
      embed_extensions_plugins_phase = self.target.copy_files_build_phases.find do |copy_phase|
        copy_phase.symbol_dst_subfolder_spec == :plug_ins
      end
      if embed_extensions_plugins_phase.nil?
        embed_extensions_plugins_phase = self.target.new_copy_files_build_phase('Embed App Extensions')
        embed_extensions_plugins_phase.symbol_dst_subfolder_spec = :plug_ins
      end
      abort "Couldn't find 'Embed App Extensions Plugin' phase" if embed_extensions_plugins_phase.nil?
      
      build_file = embed_extensions_plugins_phase.add_file_reference(nse_product)
      build_file.settings = { "ATTRIBUTES" => ['RemoveHeadersOnCopy'] }
      self.project.save()
      puts "Added NSE to App target"
    end
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
    puts "Added OneSignal Swift Package"
    self.project.save()
  end

  # add swift package binary to nse target
  def _add_onesignal_framework_to_nse()
    return if !self.nse
    self.nse.package_product_dependencies
                 .select { |product| product.product_name == 'OneSignal' }
                 .each(&:remove_from_project)

    self.nse.package_product_dependencies << self.onesignal_product_ref
    puts "Added OneSignal Dependency to NSE"
    self.project.save()
  end 

  # app groups capability
  # Creates OneSignalNotificationServiceExtension.entitlements if it doesn't exist
  def _add_app_groups_to_nse()
    return if !self.nse
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
        entitlements['com.apple.security.application-groups'].push(app_group_name)
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
    puts "Added OneSignal App Group to NSE"
    self.project.save()
  end

  # add swift package binary to main target
  def _add_onesignal_framework_to_main_target()
    self.target.package_product_dependencies
                  .select { |product| product.product_name == 'OneSignal' }
                  .each(&:remove_from_project)

    self.target.package_product_dependencies << self.onesignal_product_ref
    puts "Added OneSignal dependency to App target"
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
      puts "Added remote notification background mode"
    elsif !info_plist["UIBackgroundModes"].include? 'remote-notification'
      info_plist["UIBackgroundModes"].push('remote-notification')
      puts "Added remote notification background mode"
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
        puts "Added push notification capability"
      end
    else
      entitlements = {
        'aps-environment' => 'development'
      }
      Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
      group.new_reference(self.target_name + ".entitlements")
      self.target.build_configuration_list.set_setting('CODE_SIGN_ENTITLEMENTS', group_relative_entitlements_path)
      puts "Added push notification capability"
    end

    # Add App Group to entitlements
    bundle_id = self.target.build_configuration_list.get_setting('PRODUCT_BUNDLE_IDENTIFIER')["Debug"]
    app_group_name = 'group.' + bundle_id + '.onesignal'
    if entitlements['com.apple.security.application-groups'].nil?
      entitlements['com.apple.security.application-groups'] = [app_group_name]
      puts "Added OneSignal App Group"
    elsif !entitlements['com.apple.security.application-groups'].include? app_group_name
      entitlements['com.apple.security.application-groups'].push(app_group_name)
      puts "Added OneSignal App Group"
    end
    Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
    self.project.save()
  end

  # depends on language and app lifecycle (appdelegate vs swiftui)
  def _add_os_init_to_app_target()
  end 

end


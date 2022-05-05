require_relative 'osproject'
require_relative 'osproject_helpers'
require_relative 'osnetwork'
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

  SWIFT_NSE_PATH = '/include/iOS/swift/NotificationService.swift'
  OBJC_NSE_H_PATH = '/include/iOS/objc/NotificationService.h'
  OBJC_NSE_M_PATH = '/include/iOS/objc/NotificationService.m'
  SWIFT_NSE_INFO_PLIST_PATH = '/include/iOS/swift/Info.plist'
  OBJC_NSE_INFO_PLIST_PATH = '/include/iOS/objc/Info.plist'

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
    actions_taken = _add_capabilities_to_main_target()
    actions_taken += _add_os_init_to_app_target()
    #NSE setup
    actions_taken += _create_nse()
    actions_taken += _add_nse_to_app_target()
    actions_taken += _add_app_groups_to_nse()
    #Add OneSignal
    actions_taken += _add_onesignal_dependency()
    NetworkHandler.instance.send_track_actions(app_id: os_app_id, platform: type, lang: lang, actions_taken: actions_taken)
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
      error_track_message = "User provided a wrong xcodeproj path: #{xcproj_path};"
      NetworkHandler.instance.send_track_error(app_id: os_app_id, platform: type, lang: lang, error_message: error_track_message)
      exit(1)
    end
    
    @target = self.project.native_targets.find { |target| target.name == self.target_name}
    if !self.target
      puts "Unable to find an app target with name: " + self.target_name
      error_track_message = "User provided a wrong target name;"
      NetworkHandler.instance.send_track_error(app_id: os_app_id, platform: type, lang: lang, error_message: error_track_message)
      exit(1)
    end
    
    _add_sdk()
    
    puts "Finished Installing OneSignal"
    puts "Two steps remain for you: "
    puts "\t1. Add the OneSignal initialization code to your app, following step 5 in the manual process: https://tinyurl.com/hphtxfm7"
    puts "\t2. Generate and upload the iOS Push Certificate: https://tinyurl.com/45axmtsu"
    puts ""
    puts "\tYou should then be able to run a test notification in Xcode."
  end

  # Only use Cocoapods if a Podfile already exists. If not use SwiftPM
  def _add_onesignal_dependency()
    if File.exist?(self.dir + '/Podfile')
      return _add_onesignal_podspec_dependency()
    else 
      actions_taken = _add_onesignal_sp_dependency()
      actions_taken += _add_onesignal_framework_to_main_target()
      return actions_taken
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
      message = "Installed OneSignal pod"
      puts message
    else  
      internal_message = "Error adding OneSignal to Podfile"
      message = "error=#{internal_message}"
      puts internal_message
    end

    return "#{message};"
  end

  def _create_nse()
    # Create NSE target
    self.project.embedded_targets_in_native_target(self.target).each do |embedded_target|
      if embedded_target.name == 'OneSignalNotificationServiceExtension'
        return ""
      end
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
    search_paths = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
    self.nse.build_configuration_list.set_setting('LD_RUNPATH_SEARCH_PATHS', search_paths)
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
      plist_path = 
        if lang == :swift
          SWIFT_NSE_INFO_PLIST_PATH
        else
          OBJC_NSE_INFO_PLIST_PATH
        end
      FileUtils.cp_r(cli_dir + plist_path, nsePath)
      self.nse_group.new_reference("OneSignalNotificationServiceExtension/Info.plist")
      self.nse.build_configuration_list.set_setting('INFOPLIST_FILE', 'OneSignalNotificationServiceExtension/Info.plist')
    end
    message = "Created OneSignalNotificationServiceExtension"
    puts message
    self.project.save()
    return "#{message};"
  end

  def _add_nse_to_app_target()
    if !self.nse
      return ""
    end
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

      if embed_extensions_plugins_phase.nil?
        error_track_message = "Couldn't find 'Embed App Extensions Plugin' phase"
        NetworkHandler.instance.send_track_error(app_id: os_app_id, platform: type, lang: lang, error_message: error_track_message)
        abort error_track_message
      end
    
      build_file = embed_extensions_plugins_phase.add_file_reference(nse_product)
      build_file.settings = { "ATTRIBUTES" => ['RemoveHeadersOnCopy'] }
      self.project.save()

      message = "Added NSE to App target"
      puts message
      return "#{message};"
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
    message = "Added OneSignal Swift Package"
    puts message
    self.project.save()
    return "#{message};"
  end

  # add swift package binary to nse target
  # Not currently called due to Apple bug when archiving with an XCFramework.
  # The NSE is using the XCFramework from the main target by adding
  # @executable_path/../../Frameworks to the framework search paths
  def _add_onesignal_framework_to_nse()
    return if !self.nse
    self.nse.package_product_dependencies
                 .select { |product| product.product_name == 'OneSignal' }
                 .each(&:remove_from_project)

    self.nse.package_product_dependencies << self.onesignal_product_ref
    message = "Added OneSignal Dependency to NSE"
    puts message
    self.project.save()
    return "#{message};"
  end 

  # app groups capability
  # Creates OneSignalNotificationServiceExtension.entitlements if it doesn't exist
  def _add_app_groups_to_nse()
    if !self.nse
      return ""
    end

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
    message = "Added OneSignal App Group to NSE"
    puts message
    self.project.save()
    return "#{message};"
  end

  # add swift package binary to main target
  def _add_onesignal_framework_to_main_target()
    self.target.package_product_dependencies
                  .select { |product| product.product_name == 'OneSignal' }
                  .each(&:remove_from_project)

    self.target.package_product_dependencies << self.onesignal_product_ref
    message = "Added OneSignal dependency to App target"
    puts message
    self.project.save()
    return "#{message};"
  end 

  # push capability in entitlments
  # background capability with remote notifications enabled
  # App group entitlement based on target bundle id
  def _add_capabilities_to_main_target()
    message = ""
    #Update Info.plist of Target to include background modes with remote notifications
    plist_path = dir + "/" + self.target.build_configuration_list.get_setting('INFOPLIST_FILE')['Debug']
    info_plist = Xcodeproj::Plist.read_from_path(plist_path)
    if info_plist["UIBackgroundModes"].nil?
      info_plist["UIBackgroundModes"] = ["remote-notification"]
      message = "Added remote notification background mode"
      puts message
    elsif !info_plist["UIBackgroundModes"].include? 'remote-notification'
      info_plist["UIBackgroundModes"].push('remote-notification')
      message = "Added remote notification background mode"
      puts message 
    end

    unless message.empty?
      message = "#{message};"
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
        internal_message = "Added push notification capability"
        message += "#{internal_message};"
        puts internal_message 
      end
    else
      entitlements = {
        'aps-environment' => 'development'
      }
      Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
      group.new_reference(self.target_name + ".entitlements")
      self.target.build_configuration_list.set_setting('CODE_SIGN_ENTITLEMENTS', group_relative_entitlements_path)
      internal_message = "Added push notification capability"
      message += "#{internal_message};"
      puts internal_message 
    end

    # Add App Group to entitlements
    bundle_id = self.target.build_configuration_list.get_setting('PRODUCT_BUNDLE_IDENTIFIER')["Debug"]
    app_group_name = 'group.' + bundle_id + '.onesignal'
    if entitlements['com.apple.security.application-groups'].nil?
      entitlements['com.apple.security.application-groups'] = [app_group_name]
      internal_message = "Added OneSignal App Group"
      message += "#{internal_message};"
      puts internal_message 
    elsif !entitlements['com.apple.security.application-groups'].include? app_group_name
      entitlements['com.apple.security.application-groups'].push(app_group_name)
      internal_message = "Added OneSignal App Group"
      message += "#{internal_message};"
      puts internal_message 
    end
    Xcodeproj::Plist.write_to_path(entitlements, entitlements_path)
    self.project.save()

    return message
  end

  # depends on language and app lifecycle (appdelegate vs swiftui)
  def _add_os_init_to_app_target()
    return ""
  end
end


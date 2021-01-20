class OSProject
  attr_reader :type
  attr_reader :dir
  attr_reader :lang
  attr_reader :os_app_id

  def initialize(type, dir, lang, os_app_id)
    @type = type
    @dir = dir
    @lang = lang
    @os_app_id = os_app_id
  end

  # @abstract add_sdk is expected to be implemented by subclasses
  # @!method add_sdk
  #   Conduct the initial-setup process to add the latest OS SDK to the project
end

class OSProject::Dummy < OSProject
  def initialize(type, dir, lang, os_app_id)
    @type = type
    @dir = dir
    @lang = lang
    @os_app_id = os_app_id
  end
  def add_sdk
    puts "type:" + self.type + " dir: " + self.dir
    puts "lang:" + self.lang + " os_app_id: " + self.os_app_id
  end
end

class OSProject::Android < OSProject
  def initialize(dir, lang, os_app_id)
    @type = 'android'
    @dir = dir
    @lang = lang
    @os_app_id = os_app_id
  end
  def add_sdk
    puts "type:" + self.type + " dir: " + self.dir
    puts "lang:" + self.lang + " os_app_id: " + self.os_app_id
  end
end

class OSProject::IOS < OSProject
  def initialize(dir, lang, os_app_id)
    @type = 'ios'
    @dir = dir
    @lang = lang
    @os_app_id = os_app_id
  end
  def add_sdk
    puts "type:" + self.type + " dir: " + self.dir
    puts "lang:" + self.lang + " os_app_id: " + self.os_app_id
  end
end

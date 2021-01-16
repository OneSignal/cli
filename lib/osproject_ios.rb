require_relative 'osproject'

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
end


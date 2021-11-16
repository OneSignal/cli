require 'clamp'
require_relative 'osproject'
require_relative 'osproject_ios'
require_relative 'osproject_android'

class NetworkHandler
  @instance = new

  private_class_method :new

  URL = 'https://api.onesignal.com/api/v1/track'

  def self.instance
    @instance
  end

  def get_http_net()
    uri = URI.parse(URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    return http
  end

  def send_track_error(app_id, platform, lang, error_message)
    send_track_from_error(app_id, platform, lang, nil, error_message)
  end

  def send_track_from_error(app_id, platform, lang, success_mesage, error_message)
    error_message = "error=#{error_message}"

    if success_mesage.nil? || success_mesage.empty?
      actions_taken = error_message
    else
      actions_taken = success_mesage.gsub(" * ", "").gsub("\n",";")
      actions_taken += error_message
    end
  
    send_track_command_actions(app_id, platform, lang, OSProject.default_command, actions_taken)
  end

  def send_track_actions(app_id, platform, lang, actions_taken)
    send_track_command_actions(app_id, platform, lang, OSProject.default_command, actions_taken)
  end

  def send_track_command(command)
    http = get_http_net()

    request = Net::HTTP::Post.new(URL)

    request['app_id'] = ""
    request['OS-Usage-Data'] = get_usage_data(nil, nil, command, nil)
    
    response = http.request(request)
  end

  private

  def send_track_command_actions(app_id, platform, lang, command, actions_taken)
    http = get_http_net()

    request = Net::HTTP::Post.new(URL)

    request['app_id'] = app_id
    request['OS-Usage-Data'] = get_usage_data(platform, lang, command, actions_taken)

    response = http.request(request)
  end

  def get_usage_data(platform, lang, command, actions_taken)
    data = "lib-name=#{OSProject::TOOL_NAME},lib_version=#{OSProject::VERSION},lib-os=#{OSProject.os}"

    if platform
      data += ",lib-type=#{platform}"
    end

    if lang
      data += ",lib-lang=#{lang}"
    end

    if command
      data += ",lib-command=#{command}"
    end

    if lang
      data += ",lib-actions=#{actions_taken}"
    end

    return data
  end
end
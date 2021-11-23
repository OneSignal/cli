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
    send_track_command_actions(app_id, platform, lang, OSProject.default_command, nil, error_message)
  end

  def send_track_actions(app_id, platform, lang, actions_taken)
    send_track_command_actions(app_id, platform, lang, OSProject.default_command, actions_taken, nil)
  end

  # Send command used by the user for tracking
  # There are cases where --help, --version commands might be used, and there is no other data in addition to the command name
  def send_track_command(command)
    http = get_http_net()

    request = Net::HTTP::Post.new(URL)

    request['app_id'] = ""
    request['OS-Usage-Data'] = get_usage_data(nil, nil, command, nil)

    response = http.request(request)
  end

  private

  def send_track_command_actions(app_id, platform, lang, command, actions_taken, error_message)
    http = get_http_net()

    request = Net::HTTP::Post.new(URL)

    request['app_id'] = app_id
    request['OS-Usage-Data'] = get_usage_data(platform, lang, command, actions_taken, error_message)

    response = http.request(request)
  end

  def get_usage_data(platform, lang, command, actions_taken, error_message)
    data = "kind=sdk, name=#{OSProject::TOOL_NAME}, version=#{OSProject::VERSION}, target-os=#{OSProject.os}"

    data += ", type=#{platform}" if platform
    data += ", lang=#{lang}" if lang
    data += ", command=#{command}" if command
    data += ", actions=#{actions_taken}" if actions_taken
    data += ", error=#{error_message}" if error_message

    return data
  end
end
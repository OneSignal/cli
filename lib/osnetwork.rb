require 'clamp'
require_relative 'osproject'
require_relative 'osproject_ios'
require_relative 'osproject_android'

class NetworkHandler
    @instance = new

    private_class_method :new

    def self.instance
      @instance
    end

    def send_track_from_message(app_id, platform, lang, success_mesage, append_message)
      actions_taken = success_mesage.gsub(" * ", "").gsub("\n",";")
      actions_taken += append_message
      send_track_actions(app_id, platform, lang, actions_taken)
    end
  
    def send_track_actions(app_id, platform, lang, actions_taken)
      uri = URI.parse('https://api.onesignal.com/api/v1/track')
  
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
  
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({})
      request['app_id'] = app_id
      request['OS-Usage-Data'] = 'lib-name=' + OSProject.tool_name + ',lib-version=' + OSProject.version + ',lib-os=' + OSProject.os + ',lib-type=' + platform + ',lib-lang=' + lang + ',lib-actions=' + actions_taken

      response = http.request(request)
    end
end
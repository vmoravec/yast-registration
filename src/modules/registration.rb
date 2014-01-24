require 'uri'

module Yast
  import 'Linuxrc'
  import 'Mode'

  class RegistrationClass < Module
    REGISTRATION_PARAMETER = 'registration'

    def initialize
      @url =
        if Mode.installation
          get_url_from_params
        elsif Mode.autoinstallation
          get_url_from_autoyast_profile
        end
    end

    private

    def get_url_from_params
      parameters = Linuxrc.InstallInf("Cmdline").split
      registration_param = parameters.find {|p| p.match(/\A#{REGISTRATION_PARAMETER}=+/i) }
      registration_url = registration_param.split('=').last
    end

    def get_url_from_autoyast_profile
    end

    publish :variable => :url, :type => 'string'
  end
  Registration = RegistrationClass.new
end

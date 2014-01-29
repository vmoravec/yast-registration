##
# API for service discovery
#
# * this line contains the protocol, host, ip, name, lifetime, url
# ServiceDiscovery.find 'smt:http', :url => 'https://smt.suse.com/connect', :machine=>'bla', :scope => 'any'
# ServiceDiscovery.find 'install.suse', :protocol => 'ftp'
# ServiceDiscovery.find 'service:install.suse:http'
#
# Rules:
# * if there is only the name of the service provided, return a collection of services
# * if there is an attribute which identifies uniquely a service like url or ip,
#   return the service object, not a collection
#
# ServiceDiscovery.find(:suse_manager) # returns a collection
# ServiceDiscovery.find :install_server, :url=>'ftp://fallback.suse.cz # returns a single service if it exists
# ServiceDiscovery.find :ntp
##

require 'yast'
require 'resolv'
require 'ipaddr'

module Yast
  Yast.import 'SLP'

  module ServiceDiscovery
    class << self
      def find service_name, params={}
        SlpService.find(service_name, params)
      end

      def find_all service_name, params={}
        SlpService.all(service_name, params)
      # find_slp_service(service_name, options[:scope]).map do |slp_service|
      #   service = SlpService.new(options.merge(:name => service_name))
      #   service.match?(slp_service) ? service : nil
      # end
      end

    end

    # Prefix/URL scheme: service: [optional]
    # Service name: printer OR install.suse OR ntp
    # Protocol: lpr
    # Prefix + Service name => Abstract service type
    # Prefix + Service name + Protocol => Service Type
    # Attributes: attr1=>something, attr2=>something

    class SlpService
      SCHEME = 'service'
      BASE_ATTRIBUTES = [ :name, :ip, :host, :protocol, :lifetime, :type ]

      def self.find service_name, params
        find_slp_service(service_name, params[:scope]).find do |slp_response|
          service = new(service_name, slp_response)
          service.verify!(params)
        end
      end

      def self.all service_name, params
        slp_service_name = service_name
        slp_service_name << ":#{params[:protocol]}" if params[:protocol]
        find_slp_service(slp_service_name, params[:scope]).map do |slp_response|
          service = create(service_name, slp_response, params)
        end.compact
      end

      def self.create
        # Return nil if params (which are expectations) do not meet the
        # slp response. Otherwise return the new service
      end

      private

      def self.parse_url url
        url_parts = url.split(':')
        url_parts.first == SCHEME ? url_parts : url_parts.unshift(SCHEME.dup)
      end

      def self.discover_slp_service service_name, scope=''
        SLP.FindSrvs(service_name, scope)
      end

      attr_reader *BASE_ATTRIBUTES

      def initialize service_name, slp_data, params
        @name = service_name
        @ip = slp_data['ip']
        @host = resolve_host
        @lifetime = slp_data['lifetime']
        @protocol = params[:protocol]
        @url = NAME_PREFIX + name + protocol
        @attributes = get_attributes
      end

      def verify! params
      end

      private

      def resolve_host
        host = DnsCache.find(ip)
        return host if host

        host = Resolv.getname(ip)
        DnsCache.update(ip => host)
        host
      end

      def query_attributes
        attributes = {}
        SLP.UnicastFindSrvs(url, ip).each do |attribute|
          attr_name, value = attribute.scan(/\A\((.+)\)/).flatten.first.split('=')
          attributes[attr_name] = value
        end
        attributes
      end
    end

    module DnsCache
      def self.entries
        @entries ||= {}
      end

      def self.find ip_address
        entries[ip_address]
      end

      def self.update entry
        entries.merge!(entry)
      end
    end
  end
end

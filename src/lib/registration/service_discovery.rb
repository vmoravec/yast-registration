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

# Prefix/URL scheme: service: [optional]
# Service name: printer OR install.suse OR ntp
# Protocol: lpr
# Prefix + Service name => Abstract service type
# Prefix + Service name + Protocol => Service Type
# Attributes: attr1=>something, attr2=>something

require 'yast'
require 'resolv'
require 'ostruct'

module Yast
  Yast.import 'SLP'

  module ServiceDiscovery

    def self.find service_name, params={}
      SlpService.find(service_name, params)
    end

    def self.find_all service_name, params={}
      SlpService.all(service_name, params)
    end

    def self.list_types
      SlpService.list_types
    end

    class SlpService

      SCHEME = 'service'
      DELIMITER = ':'

      class << self
        def find service_name, params
          service = nil
          slp_service_type = [SCHEME, service_name, params[:protocol]].compact.join(DELIMITER)
          discover_slp_service(slp_service_type, params[:scope]).each do |slp_response|
            service = new(service_name, slp_response, params)
            service = service.match!(params)
            break unless service.nil?
          end
          service
        end

        def all service_name, params
          slp_service_type = [SCHEME, service_name, params[:protocol]].compact.join(DELIMITER)
          discover_slp_service(slp_service_type, params[:scope]).map do |slp_response|
            new(service_name, slp_response, params).match!(params)
          end.compact
        end

        def list_types
          available_services = []
          discovered_services = discover_available_slp_service_types
          return available_services if discovered_services.empty?

          discovered_services.each do |slp_service_type|
            available_services << parse_slp_type(slp_service_type)
          end
          available_services
        end

        private

        def parse_slp_type service_type
          type_parts = service_type.split(DELIMITER)
          case type_parts.size
          when 2
            name = protocol = type_parts.last
          when 3
            name = type_parts[1]
            protocol = type_parts[2]
          else
            raise "Incorrect slp service type: #{service.inspect}"
          end
          OpenStruct.new :name => name, :protocol => protocol
        end

        def discover_slp_service service_name, scope=''
          SLP.FindSrvs(service_name, scope)
        end

        def discover_available_slp_service_types
          SLP.FindSrvTypes('*', '')
        end
      end

      attr_reader :name, :ip, :host, :protocol, :port, :url, :lifetime
      attr_reader :slp_type, :attributes

      def initialize service_name, slp_data, params
        @name = service_name
        @ip = slp_data['ip']
        @port = slp_data['pcPort']
        @slp_type = slp_data['pcSrvType']
        @lifetime = slp_data['lifetime']
        @url = slp_data['srvurl']
        @protocol = params[:protocol] || slp_type.split(DELIMITER).last
        @host = resolve_host
        @attributes = OpenStruct.new(SLP.GetUnicastAttrMap(url, ip))
      end

      def match! params
        matches = []
        params.each do |key, value|
          if respond_to?(key)
            result = send(key).to_s
            matches << result.match(/#{value}/i)
          elsif attributes.respond_to?(key)
            result = attributes.send(key).to_s
            matches << result.match(/#{value}/i)
          else
            matches << false
          end
        end
        matches.all? ? self : nil
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
        SLP.GetUnicastAttrMap(url,ip)
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

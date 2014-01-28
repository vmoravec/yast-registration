##
# API for service discovery
#
# * this line contains the protocol, host, ip, name, lifetime, url
# ServiceDiscovery.find :smt, :url => 'https://smt.suse.com/connect', :machine=>'bla', :scope => 'any'
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
      def find service_name, options={}
        find_slp_services(service_name, options[:scope]).find do |service|
          service = Service.new(options.merge(:name => service_name))
          service.match?(slp_service) ? service : nil
        end
      end

      def find_all service_name, options={}
        find_slp_services(service_name, options[:scope]).map do |slp_service|
          service = Service.new(options.merge(:name => service_name))
          service.match?(slp_service) ? service : nil
        end
      end

      private

      def find_slp_services service_name, scope=''
        SLP.FindSrvs(service_name, scope)
      end
    end

    # Prefix/URL scheme: service: [optional]
    # Service name: printer OR install.suse OR ntp
    # Protocol: lpr
    # Prefix + Service name => Abstract service type
    # Prefix + Service name + Protocol => Service Type
    # Attributes: attr1=>something, attr2=>something

    class Service
      SCHEME = 'service:'

      attr_reader :ip, :host, :lifetime, :name, :protocol, :attributes

      def self.discover options

      end

      def initialize properties
        @ip = properties['ip']
        @host = resolve_host
        @lifetime = properties['lifetime']
        @name = properties['pcSrvType'].split(NAME_PREFIX).last
        @protocol = nil # pcSrvType? no
        @url = NAME_PREFIX + name + protocol
        @attributes = get_attributes
      end

      private

      def resolve_host
        hostname = DnsCache.find(ip)
        return hostname if hostname

        hostname = Resolv.getname(ip)
        DnsCache.update(ip => hostname)
        hostname
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

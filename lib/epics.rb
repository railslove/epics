require 'openssl'
require 'base64'
require 'erb'
require 'i18n'
require 'json'
require 'zlib'
require 'zip'
require 'nokogiri'
require 'faraday'
require 'securerandom'
require 'time'
require "epics/version"
require "epics/keyring"
require "epics/signature"
require "epics/signature_algorithm"
require "epics/signature_algorithm/base"
require "epics/signature_algorithm/rsa"
require "epics/signature_algorithm/rsapss"
require "epics/signature_algorithm/rsapkcs1"
require "epics/response"
require "epics/error"
require 'epics/letter_renderer'
require "epics/middleware/parse_ebics"
require "epics/generic_request"
require "epics/generic_upload_request"
require "epics/azv"
require "epics/hpb"
require "epics/hkd"
require "epics/htd"
require "epics/haa"
require "epics/sta"
require "epics/fdl"
require "epics/ful"
require "epics/vmk"
require "epics/bka"
require "epics/c52"
require "epics/c53"
require "epics/c54"
require "epics/c5n"
require "epics/z01"
require "epics/z52"
require "epics/z53"
require "epics/z54"
require "epics/ptk"
require "epics/hac"
require "epics/wss"
require "epics/hpd"
require "epics/cd1"
require "epics/cct"
require "epics/ccs"
require "epics/cip"
require "epics/cdb"
require "epics/cdd"
require "epics/xe2"
require "epics/xe3"
require "epics/b2b"
require "epics/xds"
require "epics/cds"
require "epics/c2s"
require "epics/cdz"
require "epics/crz"
require "epics/xct"
require "epics/hia"
require "epics/ini"
require "epics/hev"
require "epics/client"

require 'epics/builders'
require 'epics/crypt'
require 'epics/factories'
require 'epics/handlers'
require 'epics/services'

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'letter/locales', '*.yml')]

module Epics
  DEFAULT_PRODUCT_NAME = 'EPICS - a ruby ebics kernel'
  DEFAULT_LOCALE = :de

  # EBICS 3.0 (H005) carries public keys inside `ds:X509Data`, which the key management
  # schemas declare mandatory (EBICS 3.0.2 §3.9). There is no raw modulus/exponent form.
  class MissingCertificateError < StandardError
    attr_reader :signature_version, :option_name

    def initialize(signature_version, option_name)
      @signature_version = signature_version
      @option_name = option_name
      super("EBICS 3.0 (H005) requires an X.509 certificate for #{signature_version}. " \
            "Pass #{option_name}: to Epics::Client.new, or use Epics::Client.setup " \
            'to generate a self-signed one.')
    end
  end

  # Raised when a check needs a key the client has not loaded, e.g. verifying a bank
  # signature before HPB has run.
  class MissingKeyError < StandardError
    def initialize(what)
      super("#{what} is not available; run HPB or load a key file that contains it")
    end
  end

  class InvalidCertificateError < StandardError
    attr_reader :source

    # `source` says where the certificate came from: a constructor option name, or a
    # description such as "the HPB response".
    def initialize(source, original = nil)
      @source = source
      message = "Could not parse the X.509 certificate from #{source}"
      message += " (#{original.message})" if original
      super(message)
    end
  end

  class VersionSupportError < StandardError
    attr_reader :version

    def initialize(version, direction = 'above')
      @version = version
      message = case direction
      when 'above'
        "Supported from version #{version}"
      when 'below'
        "Support for versions below #{version}"
      else
        raise ArgumentError, "Invalid direction: #{direction}. Use 'above' or 'below'."
      end
      super(message)
    end
  end
end

Ebics = Epics

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
require "epics/signature_algorithm"
require "epics/signature_algorithm/base"
require "epics/signature_algorithm/rsa"
require "epics/signature_algorithm/rsapss"
require "epics/signature_algorithm/rsapkcs1"
require "epics/response"
require "epics/error"
require 'epics/letter_renderer'
require "epics/middleware/xmlsig"
require "epics/middleware/parse_ebics"
require "epics/generic_request"
require "epics/generic_upload_request"
require "epics/header_request"
require "epics/azv"
require "epics/hpb"
require "epics/hkd"
require "epics/htd"
require "epics/haa"
require "epics/sta"
require "epics/vmk"
require "epics/c52"
require "epics/c53"
require "epics/c54"
require "epics/z52"
require "epics/z53"
require "epics/z54"
require "epics/ptk"
require "epics/hac"
require "epics/hpd"
require "epics/cd1"
require "epics/cct"
require "epics/ccs"
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
require "epics/signer"
require "epics/client"

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'letter/locales', '*.yml')]

module Epics

end
Ebics = Epics

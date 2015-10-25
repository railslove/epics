require 'openssl'
require 'base64'
require 'erb'
require 'json'
require 'zlib'
require 'zip'
require 'nokogiri'
require 'gyoku'
require 'faraday'
require 'securerandom'
require 'time'
require "epics/version"
require "epics/key"
require "epics/mgf"
require "epics/response"
require "epics/error"
require "epics/middleware/xmlsig"
require "epics/middleware/parse_ebics"
require "epics/generic_request"
require "epics/generic_upload_request"
require "epics/hpb"
require "epics/hkd"
require "epics/htd"
require "epics/haa"
require "epics/sta"
require "epics/c52"
require "epics/c53"
require "epics/c54"
require "epics/ptk"
require "epics/hac"
require "epics/hpd"
require "epics/cd1"
require "epics/cct"
require "epics/cdb"
require "epics/cdd"
require "epics/hia"
require "epics/ini"
require "epics/signer"
require "epics/client"

module Epics

end
Ebics = Epics

require 'openssl'
require 'base64'
require 'erb'
require 'json'
require 'nokogiri'
require 'gyoku'
require 'faraday'

require "epics/version"
require "epics/key"
require "epics/mgf"
require "epics/response"
require "epics/middleware/xmlsig"
require "epics/middleware/parse_ebics"
require "epics/generic_request"
require "epics/generic_upload_request"
require "epics/hpb"
require "epics/htd"
require "epics/haa"
require "epics/sta"
require "epics/ptk"
require "epics/hpd"
require "epics/cd1"
require "epics/cct"
require "epics/cdd"
require "epics/hia"
require "epics/ini"
require "epics/signer"
require "epics/client"
require "epics/commands"

class Epics

  def initialize(*args)
    @client = Client.new(*args)
  end

  def self.initialize(passphrase, keysize = 2048)
    @client = Client.new(nil, passphrase, nil, nil, nil, nil)
    @client.keys = %w(A006 X002 E002).each_with_object({}) do |type, memo|
      memo[type] = Epics::Key.new( OpenSSL::PKey::RSA.generate(keysize) )
    end

    @client.send(:dump_keys)
  end

  def credit(document)
    @client.CCT(document)
  end

  def debit(document, type = :CDD)
    @client.send(type, document)
  end

  def statements(from, to, type = :STA)
    @client.send(type, from, to)
  end
end

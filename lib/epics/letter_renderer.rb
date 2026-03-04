class Epics::LetterRenderer
  extend Forwardable

  I18N_SCOPE = 'epics.letter'

  def initialize(client)
    @client = client
    @digest_resolver = case client.version
    when Epics::Keyring::VERSION_24, Epics::Keyring::VERSION_25
      Epics::Services::DigestResolver::V2.new
    when Epics::Keyring::VERSION_30
      Epics::Services::DigestResolver::V3.new
    end
  end

  def translate(key, **options)
    I18n.translate(key, **{ locale: @client.locale, scope: I18N_SCOPE }.merge(options))
  end

  alias t translate

  def_delegators @digest_resolver, :confirm_digest
  def_delegators :@client, :keyring,
                 :host_id, :user_id, :partner_id,
                 :signature_version, :signature_key,
                 :encryption_version, :encryption_key,
                 :authentication_version, :authentication_key

  alias_method :a, :signature_key
  alias_method :e, :encryption_key
  alias_method :x, :authentication_key

  def render(bankname)
    template_path = File.join(File.dirname(__FILE__), '../letter/', template_filename)
    ERB.new(File.read(template_path)).result(binding)
  end

  def template_filename
    use_x_509_certificate_template? ? 'ini_with_certs.erb' : 'ini.erb'
  end

  def use_x_509_certificate_template?
    [keyring.user_signature, keyring.user_authentication, keyring.user_encryption].all? { |s| s.certificate }
  end
end

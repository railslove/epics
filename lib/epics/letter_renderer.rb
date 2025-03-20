class Epics::LetterRenderer
  extend Forwardable

  TEMPLATE_PATH = File.join(File.dirname(__FILE__), '../letter/', 'ini.erb')
  I18N_SCOPE = 'epics.letter'

  def initialize(client)
    @client = client
  end

  def translate(key, **options)
    I18n.translate(key, **{ locale: @client.locale, scope: I18N_SCOPE }.merge(options))
  end

  alias_method :t, :translate

  def_delegators :@client, :host_id, :user_id, :partner_id,
                 :signature_version, :signature_key,
                 :encryption_version, :encryption_key,
                 :authentication_version, :authentication_key

  alias_method :a, :signature_key
  alias_method :e, :encryption_key
  alias_method :x, :authentication_key

  def render(bankname)
    ERB.new(File.read(TEMPLATE_PATH)).result(binding)
  end
end

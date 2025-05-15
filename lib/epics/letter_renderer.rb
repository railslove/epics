class Epics::LetterRenderer
  extend Forwardable

  I18N_SCOPE = 'epics.letter'

  def initialize(client)
    @client = client
  end

  def translate(key, **options)
    I18n.translate(key, **{ locale: @client.locale, scope: I18N_SCOPE }.merge(options))
  end

  alias t translate

  def_delegators :@client, :host_id, :user_id, :partner_id, :a, :x, :e,
                 :x_509_certificate_a_hash, :x_509_certificate_x_hash, :x_509_certificate_e_hash,
                 :x_509_certificate_a_content, :x_509_certificate_x_content, :x_509_certificate_e_content

  def render(bankname)
    template_path = File.join(File.dirname(__FILE__), '../letter/', template_filename)
    ERB.new(File.read(template_path)).result(binding)
  end

  def template_filename
    use_x_509_certificate_template? ? 'ini_with_certs.erb' : 'ini.erb'
  end

  def use_x_509_certificate_template?
    x_509_certificate_a_content && x_509_certificate_x_content && x_509_certificate_e_content
  end
end

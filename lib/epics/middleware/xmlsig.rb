class Epics::XMLSIG < Faraday::Middleware

  def initialize(app, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    @signer = Epics::Signer.new(@client, env['body'])
    @signer.digest!
    @signer.sign!

    env.request_headers['Content-Type']= ''
    env['body'] = @signer.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

    @app.call(env)
  end

end

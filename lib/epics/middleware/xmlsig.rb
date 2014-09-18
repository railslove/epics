class Epics::XMLSIG < Faraday::Middleware

  def initialize(app, options = {})
    super(app)
    @client = options[:client]
  end

  def call(env)
    @signer = Epics::Signer.new(@client, env["body"])
    require "pry"; binding.pry
    @signer.digest!
    @signer.sign!

    env["body"] = @signer.doc.to_xml

    @app.call(env)
  end

end

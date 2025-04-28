class Epics::Handlers::UserSignatureHandler::Base
  def initialize(client)
    @client = client
    @crypt_service = Epics::Services::CryptService.new
  end

  def handle(digest)
    raise NotImplementedError
  end
end
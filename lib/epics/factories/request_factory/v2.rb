class Epics::Factories::RequestFactory::V2 < Epics::Factories::RequestFactory::Base
  ['btd btu'].each do |type|
    define_method("create_#{type}") { |*| raise Epics::VersionSupportError, 3.0 }
  end

  def initialize(client)
    @digest_resolver = Epics::Services::DigestResolver::V2.new
    @user_signature_handle = Epics::Handlers::UserSignatureHandler::V2.new(client)
    super
  end
end

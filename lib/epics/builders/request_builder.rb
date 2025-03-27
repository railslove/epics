class Epics::Builders::RequestBuilder
  def initialize(xml_builder)
    @xml_builder = xml_builder
  end

  def add_container_unsecured(&)
    @xml_builder.create_unsecured(&)
  end

  def add_container_secured_no_pubkey_digests(&)
    @xml_builder.create_secured_no_pubkey_digests(&)
  end

  def add_container_secured(&)
    @xml_builder.create_secured(&)
  end

  def add_container_unsigned(&)
    @xml_builder.create_unsigned(&)
  end

  def add_container_hev(&)
    @xml_builder.create_hev(&)
  end
end

class Epics::Handlers::OrderDataHandler::V25 < Epics::Handlers::OrderDataHandler::V2
  protected

  def h00x_version
    'H004'
  end

  def h00x_namespace
    'urn:org:ebics:H004'
  end
end

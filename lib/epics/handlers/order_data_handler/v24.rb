class Epics::Handlers::OrderDataHandler::V24 < Epics::Handlers::OrderDataHandler::V2
  protected

  def h00x_version
    'H003'
  end

  def h00x_namespace
    'http://www.ebics.org/H003'
  end
end

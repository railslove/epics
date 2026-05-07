# frozen_string_literal: true

class Epics::FDL < Epics::GenericRequest
  def to_xml
    builder = request_factory.create_fdl(options[:file_format], options[:from], options[:to])
    builder.to_xml
  end
end

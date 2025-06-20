class Epics::HAC < Epics::GenericRequest
  # By default HAC only returns data for transactions which have not yet been fetched. Therefore,
  # most applications not not have to specify a date range, but can simply fetch the status and
  # be done
  def to_xml
    builder = request_factory.create_hac(options[:from], options[:to])
    builder.to_xml
  end
end

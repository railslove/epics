RSpec::Matchers.define :be_a_valid_ebics_doc do |version|
  ##
  # use #open instead of #read to have the includes working
  # http://stackoverflow.com/questions/11996326/nokogirixmlschema-syntaxerror-on-schema-load/22971456#22971456
  def xsd(version)
    @xsd ||= {}
    @xsd[version] ||= Nokogiri::XML::Schema(case version
    when Epics::Keyring::VERSION_25
      File.open( File.join( File.dirname(__FILE__), '..', 'xsd', 'H004', 'ebics_H004.xsd') )
    when Epics::Keyring::VERSION_24
      File.open( File.join( File.dirname(__FILE__), '..', 'xsd', 'H003', 'ebics.xsd') )
    end)
  end

  match do |actual|
    xsd(version).valid?(Nokogiri::XML(actual))
  end

  failure_message do |actual|
    "expected that #{actual} would be a valid EBICS doc:\n\n #{xsd(version).validate(Nokogiri::XML(actual))}"
  end

  description do
    'be a valid EBICS document'
  end
end

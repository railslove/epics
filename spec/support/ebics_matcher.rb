RSpec::Matchers.define :be_a_valid_ebics_doc do

  ##
  # use #open instead of #read to have the includes working
  # http://stackoverflow.com/questions/11996326/nokogirixmlschema-syntaxerror-on-schema-load/22971456#22971456
  def xsd
    @xsd ||= Nokogiri::XML::Schema(File.open( File.join( File.dirname(__FILE__), '..', 'xsd', 'ebics_H004.xsd') ))
  end

  match do |actual|
    xsd.valid?(Nokogiri::XML(actual))
  end

  failure_message do |actual|
    "expected that #{actual} would be a valid EBICS doc:\n\n #{xsd.validate(Nokogiri::XML(actual))}"
  end

  description do
    "be a valid EBCIS document"
  end

end
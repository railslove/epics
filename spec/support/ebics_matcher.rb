# Root schema per EBICS protocol version. Drop the official H005 schema set into
# spec/xsd/ (ebics_H005.xsd + its includes) to enable H005 validation.
EBICS_XSD_ROOT = {
  h004: 'ebics_H004.xsd',
  h005: 'ebics_H005.xsd',
}.freeze

def ebics_xsd_path(version)
  File.join(File.dirname(__FILE__), '..', 'xsd', EBICS_XSD_ROOT.fetch(version))
end

# True when the XSD schema set for the given EBICS version is available locally.
def ebics_xsd_available?(version)
  File.exist?(ebics_xsd_path(version))
end

RSpec::Matchers.define :be_a_valid_ebics_doc do |version = :h004|

  ##
  # use #open instead of #read to have the includes working
  # http://stackoverflow.com/questions/11996326/nokogirixmlschema-syntaxerror-on-schema-load/22971456#22971456
  def xsd(version)
    @xsd ||= Nokogiri::XML::Schema(File.open(ebics_xsd_path(version)))
  end

  match do |actual|
    xsd(version).valid?(Nokogiri::XML(actual))
  end

  failure_message do |actual|
    "expected that #{actual} would be a valid EBICS doc:\n\n #{xsd(version).validate(Nokogiri::XML(actual))}"
  end

  description do
    "be a valid EBICS document"
  end

end

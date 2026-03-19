class Epics::Handlers::AuthSignatureHandler
  def initialize(keyring)
    @keyring = keyring
    @crypt_service = Epics::Services::CryptService.new
  end

  def handle(xml_builder)
    signature_path = "//*[@authenticate='true']"
    signature_method_algorithm = 'sha256'
    digest_method_algorithm = 'sha256'
    canonicalization_method_algorithm = 'REC-xml-c14n-20010315'
    digest_transform_algorithm = 'REC-xml-c14n-20010315'

    canonicalized_header = calculate_c14n(xml_builder.xml, signature_path, digest_transform_algorithm)
    canonicalized_header_hash = @crypt_service.hash(canonicalized_header, digest_method_algorithm)

    # Step 1: Build AuthSignature with SignedInfo and a placeholder SignatureValue
    Nokogiri::XML::Builder.new do |xml|
      @xml = xml
      xml.AuthSignature do
        xml.send('ds:SignedInfo') do
          xml.send('ds:CanonicalizationMethod', Algorithm: urn_algorithm(canonicalization_method_algorithm))
          xml.send('ds:SignatureMethod', Algorithm: "http://www.w3.org/2001/04/xmldsig-more#rsa-#{signature_method_algorithm}")
          xml.send('ds:Reference', URI: "#xpointer(#{signature_path})") do
            xml.send('ds:Transforms') do
              xml.send('ds:Transform', Algorithm: urn_algorithm(digest_transform_algorithm))
            end
            xml.send('ds:DigestMethod', Algorithm: "http://www.w3.org/2001/04/xmlenc##{digest_method_algorithm}")
            xml.send('ds:DigestValue', Base64.strict_encode64(canonicalized_header_hash))
          end
        end
        xml.send('ds:SignatureValue', 'PLACEHOLDER')
      end
    end

    # Step 2: Insert AuthSignature into the actual main document (before <body>)
    xml_builder.xml.parent.children.last.add_previous_sibling @xml.parent.root

    # Step 3: Canonicalize ds:SignedInfo from the main document context
    # This ensures namespace inheritance matches what the bank will compute
    signed_info_node = xml_builder.xml.doc.at_xpath(
      '//ds:SignedInfo',
      'ds' => 'http://www.w3.org/2000/09/xmldsig#'
    )
    c14n_mode = Nokogiri::XML::XML_C14N_1_0
    canonicalized_signed_info = signed_info_node.canonicalize(c14n_mode)

    # Step 4: Sign and replace placeholder with actual SignatureValue
    canonicalized_signed_info_hash_encrypted = @crypt_service.encrypt(@keyring.user_authentication,
                                                                      canonicalized_signed_info)
    signature_value_node = xml_builder.xml.doc.at_xpath(
      '//ds:SignatureValue',
      'ds' => 'http://www.w3.org/2000/09/xmldsig#'
    )
    signature_value_node.content = Base64.strict_encode64(canonicalized_signed_info_hash_encrypted)
  end

  def to_xml
    @xml.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML, encoding: 'utf-8')
  end

  private

  def urn_algorithm(algorithm, with_comments = false)
    urn = case algorithm
          when 'xml-exc-c14n'
            'http://www.w3.org/2001/10/'
          when 'REC-xml-c14n-20010315'
            'http://www.w3.org/TR/2001/'
          when 'REC-xml-c14n11-20080502'
            'http://www.w3.org/TR/2008/'
          else
            raise UnknownAlgorithmException, algorithm
          end
    urn += algorithm
    urn += '#WithComments' if with_comments
    urn
  end

  def calculate_c14n(xml, path, algorithm = 'REC-xml-c14n-20010315', with_comments = false)
    mode = case algorithm
           when 'xml-exc-c14n'
             Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
           when 'REC-xml-c14n-20010315'
             Nokogiri::XML::XML_C14N_1_0
           when 'REC-xml-c14n11-20080502'
             Nokogiri::XML::XML_C14N_1_1
           else
             raise UnknownAlgorithmException, algorithm
           end
    xml.doc.xpath(path).map { |node| node.canonicalize(mode, nil, with_comments) }.join
  end

  class UnknownAlgorithmException < StandardError
    attr_reader :algorithm

    def initialize(algorithm)
      @algorithm = algorithm
      super("Unknown algorithm: #{algorithm}")
    end
  end
end

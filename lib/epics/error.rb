class Epics::Error < StandardError

  attr_reader :code

  def to_s
    [@error.fetch("symbol", "EPICS_UNKNOWN"), @error.fetch("short_text", "unknown")].join(" - ")
  end

  def initialize(code)
    @code = code
    @error = self.class::ERRORS.fetch(code, {})
  end

  def symbol
    @error.fetch("symbol", "EPICS_UNKNOWN")
  end

  def short_text
    @error.fetch("short_text", "unknown")
  end


  class TechnicalError < self
    ERRORS = {
      "000000" => {
        "symbol" => "EBICS_OK",
        "short_text" => "OK",
        "meaning" => "No technical errors occurred during processing of the EBICS request",
      },
      "011000" => {
        "symbol" => "EBICS_DOWNLOAD_POSTPROCESS_DONE",
        "short_text" => "Positive acknowledgement received",
        "meaning" => "After receipt of a positive acknowledgement the download task was finished at the server's end and the EBICS transaction ended.",
      },
      "011001" => {
        "symbol" => "EBICS_DOWNLOAD_POSTPROCESS_SKIPPED",
        "short_text" => "Negative acknowledgement received",
        "meaning" => "After receipt of a negative acknowledgement the transaction was ended at the server's end without finishing the download task",
      },
      "011101" => {
        "symbol" => "EBICS_TX_SEGMENT_NUMBER_UNDERRUN",
        "short_text" => "Segment number not reached",
        "meaning" => "The total number of segments transmitted during transaction initialisation was not reached (i.e. the attribute @lastSegment was set to \"true\" before the specified segment number was reached)",
      },
      "031001" => {
        "symbol" => "EBICS_ORDER_PARAMS_IGNORED",
        "short_text" => "Unknown order parameters are ignored",
        "meaning" => "E.g. OrderParams for Upload specified",
      },
      "061001" => {
        "symbol" => "EBICS_AUTHENTICATION_FAILED",
        "short_text" => "Authentication signature error",
        "meaning" => "Verification of the authentication signature was not successful",
      },
      "061002" => {
        "symbol" => "EBICS_INVALID_REQUEST",
        "short_text" => "Message not EBICSconformant",
        "meaning" => "The syntax of the received message does not conform with EBICS specifications",
      },
      "061099" => {
        "symbol" => "EBICS_INTERNAL_ERROR",
        "short_text" => "Internal EBICS error",
        "meaning" => "An internal error occurred during",
      },
      "061101" => {
        "symbol" => "EBICS_TX_RECOVERY_SYNC",
        "short_text" => "Synchronisation necessary",
        "meaning" => "Recovery of the transaction requires synchronisation between the customer system and the bank system Continuation of the transaction using the recovery point from the bank system's EBICS response",
      },
      "091002" => {
        "symbol" => "EBICS_INVALID_USER_OR_USER_STATE",
        "short_text" => "Subscriber unknown or subscriber state inadmissible",
        "meaning" => "Either the initiating party is not known to the bank system or the subscriber state that is stored in the bank of the initiating party is inadmissible with regard to the order type",
      },
      "091003" => {
        "symbol" => "EBICS_USER_UNKNOWN",
        "short_text" => "Subscriber unknown",
        "meaning" => "The initiating party is not known to the bank system",
      },
      "091004" => {
        "symbol" => "EBICS_INVALID_USER_STATE",
        "short_text" => "Subscriber state unknown",
        "meaning" => "The subscriber state of the initiating party that is stored in the bank system is inadmissible with regard to the order type",
      },
      "091005" => {
        "symbol" => "EBICS_INVALID_ORDER_TYPE",
        "short_text" => "Order type inadmissible",
        "meaning" => "The order type is unknown or not approved for use with EBICS",
      },
      "091006" => {
        "symbol" => "EBICS_UNSUPPORTED_ORDER_TYPE",
        "short_text" => "Order type not supported",
        "meaning" => "The selected order type is optional with EBICS and is not supported by the financial institution",
      },
      "091007" => {
        "symbol" => "EBICS_DISTRIBUTED_SIGNATURE_AUTHORISATION_FAILED",
        "short_text" => "Subscriber possesses no authorisation of signature for the referenced order in the VEU administration (Request recent signature folder)",
        "meaning" => "Retrieve recent signature folder with permissible orders of order type HVU (or HVZ, respectively)",
      },
      "091008" => {
        "symbol" => "EBICS_BANK_PUBKEY_UPDATE_REQUIRED",
        "short_text" => "Bank key invalid",
        "meaning" => "The public bank key that is available to the subscriber is invalid",
      },
      "091009" => {
        "symbol" => "EBICS_SEGMENT_SIZE_EXCEEDED",
        "short_text" => "Segment size exceeded",
        "meaning" => "The specified size of an upload order data segment (in the case of H003: 1 MB) has been exceeded",
      },
      "091010" => {
        "symbol" => "EBICS_INVALID_XML",
        "short_text" => "XML invalid according to EBICS XML schema",
        "meaning" => "XML validation with EBICS schema failed or XML not well-formed",
      },
      "091011" => {
        "symbol" => "EBICS_INVALID_HOST_ID",
        "short_text" => "The transmitted HostID is unknown on the bank's side",
        "meaning" => "The transmitted HostID is unknown on the bank's side. The use of this code is only provided for the HEV request Check the used HostID and correct it. Consultation with the bank, if necessary",
      },
      "091101" => {
        "symbol" => "EBICS_TX_UNKNOWN_TXID",
        "short_text" =>  "Transaction ID invalid",
        "meaning"  => "The supplied transaction ID is invalid",
      },
      "091102" => {
        "symbol" => "EBICS_TX_ABORT",
        "short_text" => "Transaction cancelled",
        "meaning" => "The transaction was cancelled at the server's end since recovery of the transaction is not supported or is no longer possible due to the recovery counter being too high",
      },
      "091103" => {
        "symbol" => "EBICS_TX_MESSAGE_REPLAY",
        "short_text" => "Suspected Message replay (wrong time/time zone or nonce error)",
        "meaning" => "A message replay has been identified (Nonce/Timestamp pair doubled) or the difference of clock time between client and server exceeds the (parametrisable) tolerance limit",
      },
      "091104" => {
        "symbol" => "EBICS_TX_SEGMENT_NUMBER_EXCEEDED",
        "short_text" => "Segment number exceeded",
        "meaning" => "The total segment number from transaction initialisation was exceeded, i.e. the attribute @lastSegment was set to \"false\" when the last segment was transmitted",
      },
      "091112" => {
        "symbol" => "EBICS_INVALID_ORDER_PARAMS",
        "short_text" => "Invalid order parameters",
        "meaning" => "The content of OrderParams is invalid, e.g. if starting off behind the end in case of StandardOrderParams, or, in case of HVT, fetchOffset is higher than NumOrderInfos (total number of particular order information of an order)",
      },
      "091113" => {
        "symbol" => "EBICS_INVALID_REQUEST_CONTENT",
        "short_text" => "Message content semantically not compliant to EBICS",
        "meaning" => "The received message complies syntactically EBICS XML schema, but not semantically to the EBICS guidelines, e.g. IZV upload with UZHNN requires NumSegments = 0",
      },
      "091117" => {
        "symbol" => "EBICS_MAX_ORDER_DATA_SIZE_EXCEEDED",
        "short_text" => "The bank system does not support the requested order size",
        "meaning" => "Upload or download of an order file of improper size (e.g. for HVT, IZV, STA)",
      },
      "091118" => {
        "symbol" => "EBICS_MAX_SEGMENTS_EXCEEDED",
        "short_text" => "Submitted number of segments for upload is too high",
        "meaning" => "The bank system does not support the specified total number of segments for upload",
      },
      "091119" => {
        "symbol" => "EBICS_MAX_TRANSACTIONS_EXCEEDED",
        "short_text" => "Maximum number of parallel transactions per customer is exceeded",
        "meaning" => "The maximum number of parallel EBICS transactions defined in the bank system for the customer has been exceeded",
      },
      "091120" => {
        "symbol" => "EBICS_PARTNER_ID_MISMATCH",
        "short_text" => "The partner ID (=customer ID) of the ES file is not identical to the partner ID (=customer ID) of the submitter.",
        "meaning" => "On verifying the submitted signatures a partner ID was found in the document UserSignatureData that is not identical to the subscriber's partner ID in the request header",
      },
      "091121" => {
        "symbol" => "EBICS_INCOMPATIBLE_ORDER_ATTRIBUTE",
        "short_text" => "The specified order attribute is not compatible with the order in the bank system",
        "meaning" => "Case 1) File with order attribute \"DZHNN\" or \"OZHNN\" submitted with an orderId or Case 2) File with order attribute \"UZHNN\" submitted without an orderId or with orderID which is already used for \"DZHNN\" File with order attribute \"DZHNN\" submitted with an orderId",
      }
    }
  end

  class BusinessError < self
    ERRORS =  {
      "000000" => {
        "symbol" => "EBICS_OK",
        "short_text" => "OK",
        "meaning" => "No technical errors occurred during processing of the EBICS request",
      },
      "011301" => {
        "symbol" => "EBICS_NO_ONLINE_CHECKS",
        "short_text" => "Optional preliminary verification is not supported by the bank system"
      },
      "091001" => {
        "symbol" => "EBICS_DOWNLOAD_SIGNED_ONLY",
        "short_text" => "The bank system only supports bank-technically signed download order data for the order in question"
      },
      "091002" => {
        "symbol" => "EBICS_DOWNLOAD_UNSIGNED_ONLY",
        "short_text" => "The bank system only supports unsigned download order data for the order in question"
      },
      "090003" => {
        "symbol" => "EBICS_AUTHORISATION_ORDER_TYPE_FAILED",
        "short_text" => "The subscriber is not entitled to submit orders of the selected order type"
      },
      "090004" => {
        "symbol" => "EBICS_INVALID_ORDER_DATA_FORMAT",
        "short_text" => "The transferred order data does not correspond with the specified format"
      },
      "090005" => {
        "symbol" => "EBICS_NO_DOWNLOAD_DATA_AVAILABLE",
        "short_text" => "No data are available at present for the selected download order type"
      },
      "090006" => {
        "symbol" => "EBICS_UNSUPPORTED_REQUEST_FOR_ORDER_INSTANCE",
        "short_text" => "The bank system does not support the selected order request for the concrete business transaction associated with this order"
      },
      "091105" => {
        "symbol" => "EBICS_RECOVERY_NOT_SUPPORTED",
        "short_text" => "The bank system does not support Recovery"
      },
      "091111" => {
        "symbol" => "EBICS_INVALID_SIGNATURE_FILE_FORMAT",
        "short_text" => "The submitted ES files do not comply with the defined format The ES file cannot be parsed syntactically (no business-related verification!)"
      },
      "091114" => {
        "symbol" => "EBICS_ORDERID_UNKNOWN",
        "short_text" => "The submitted order number is unknown"
      },
      "091115" => {
        "symbol" => "EBICS_ORDERID_ALREADY_EXISTS",
        "short_text" => "The submitted order number is already existent"
      },
      "091116" => {
        "symbol" => "EBICS_PROCESSING_ERROR",
        "short_text" => "During processing of the EBICS request, other business-related errors have ocurred"
      },
      "091201" => {
        "symbol" => "EBICS_KEYMGMT_UNSUPPORTED_VERSION_SIGNATURE",
        "short_text" => "The algorithm version of the bank-technical signature key is not supported by the financial institution (order types INI, HCS and PUB)"
      },
      "091202" => {
        "symbol" => "EBICS_KEYMGMT_UNSUPPORTED_VERSION_AUTHENTICATION",
        "short_text" => "The algorithm version of theauthentication key is notsupported by the financialinstitution (order types HIA,HSA and HCA)"
      },
      "091203" => {
        "symbol" => "EBICS_KEYMGMT_UNSUPPORTED_VERSION_ENCRYPTION",
        "short_text" => "The algorithm version of the encryption key is not supported by the financial institution (order types HIA, HSA and HCA) This error message is returned particularly when the process ID E001 is used which is invalid from schema version H003 on"
      },
      "091204" => {
        "symbol" => "EBICS_KEYMGMT_KEYLENGTH_ERROR_SIGNATURE",
        "short_text" => "The key length of the banktechnical signature key is not supported by the financial institution (order types INI and PUB or HCS)"
      },
      "091205" => {
        "symbol" => "EBICS_KEYMGMT_KEYLENGTH_ERROR_AUTHENTICATION",
        "short_text" => "The key length of the authentication key is not supported by the financial institution (order types HIA, HSA, HCS and HCA)"
      },
      "091206" => {
        "symbol" => "EBICS_KEYMGMT_KEYLENGTH_ERROR_ENCRYPTION",
        "short_text" => "The key length of the encryption key is not supported by the financial institution (order types HIA, HSA, HCS and HCA)"
      },
      "091207" => {
        "symbol" => "EBICS_KEYMGMT_NO_X509_SUPPORT",
        "short_text" => "The bank system does not support the evaluation of X.509 data (order types INI, HIA, HSA, PUB, HCA, HCS)"
      },
      "091208" => {
        "symbol" => "EBICS_X509_CERTIFICATE_EXPIRED",
        "short_text" => "certificate is not valid because it has expired"
      },
      "091209" => {
        "symbol" => "EBICS_X509_ERTIFICATE_NOT_VALID_YET",
        "short_text" => "certificate is not valid because it is not yet in effect"
      },
      "091210" => {
        "symbol" => "EBICS_X509_WRONG_KEY_USAGE",
        "short_text" => "When verifying the certificate key usage, it has been detected that the certificate has not been issued for the current use. (only applies when key management order types are used)"
      },
      "091211" => {
        "symbol" => "EBICS_X509_WRONG_ALGORITHM",
        "short_text" => "When verifying the certificate algorithm, it has been detected that the certificate has not been issued for the current use. (only applies when key management order types are used)"
      },
      "091212" => {
        "symbol" => "EBICS_X509_INVALID_THUMBPRINT",
        "short_text" => "Reserved for next version"
      },
      "091213" => {
        "symbol" => "EBICS_X509_CTL_INVALID",
        "short_text" => "When verifying the certificate, it has been detected that the certificate trust list (CTL) is not valid because, for example, it has expired."
      },
      "091214" => {
        "symbol" => "EBICS_X509_UNKNOWN_CERTIFICATE_AUTHORITY",
        "short_text" => "The chain cannot be verified due to an unknown certificate authority (CA) If OrderType = INI, PUB or HCS and X509v3 supported: The Reject of the Request is mandatory, if signature class <> \"T\""
      },
      "091215" => {
        "symbol" => "EBICS_X509_INVALID_POLICY",
        "short_text" => "Reserved for next version"
      },
      "091216" => {
        "symbol" => "EBICS_X509_INVALID_BASIC_CONSTRAINTS",
        "short_text" => "Reserved for next version"
      },
      "091217" => {
        "symbol" => "EBICS_ONLY_X509_SUPPORT",
        "short_text" => "With respect to certificates, the bank system only supports the evaluation of X.509 data"
      },
      "091218" => {
        "symbol" => "EBICS_KEYMGMT_DUPLICATE_KEY",
        "short_text" => "During the key management request, it has been detected that the key or certificate sent for authentication or for encryption is the same as the signature key/certificate (INI, HIA, PUB, HCS,..)"
      },
      "091219" => {
        "symbol" => "EBICS_CERTIFICATES_VALIDATION_ERROR",
        "short_text" => "The server is unable to match the certificate (ES key) with the previously declared information automatically."
      },
      "091301" => {
        "symbol" => "EBICS_SIGNATURE_VERIFICATION_FAILED",
        "short_text" => "Verification of the ES has failed In the case of asynchronouslyimplemented orders, the error can occur during preliminary verification."
      },
      "091302" => {
        "symbol" => "EBICS_ACCOUNT_AUTHORISATION_FAILED",
        "short_text" => "Preliminary verification of the account authorisation has failed"
      },
      "091303" => {
        "symbol" => "EBICS_AMOUNT_CHECK_FAILED",
        "short_text" => "Preliminary verification of the account amount limit has failed"
      },
      "091304" => {
        "symbol" => "EBICS_SIGNER_UNKNOWN",
        "short_text" => "A signatory of the order in question is not a valid subscriber."
      },
      "091305" => {
        "symbol" => "EBICS_INVALID_SIGNER_STATE",
        "short_text" => "The state of a signatory in the order in question is not admissible."
      },
      "091306" => {
        "symbol" => "EBICS_DUPLICATE_SIGNATURE",
        "short_text" => "The signatory has already signed the order on hand."
      }
    }
  end

end

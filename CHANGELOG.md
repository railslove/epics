### 3.1.2

- [FIX] A non-2xx HTTP response, e.g. a `503 Service Unavailable` page during a bank's
  maintenance window, raised `Epics::Error::TechnicalError` with
  `EPICS_UNKNOWN - unknown` and lost the HTTP status. It now raises
  `Epics::Error::HTTPError` with `status` and an excerpt of the `body`, and the message
  reads e.g. `HTTP 503 Service Unavailable` (#197)
- [FIX] A 2xx response that is not an EBICS document now raises
  `Epics::Error::UnexpectedResponse` with an excerpt of the `body`, instead of
  `EPICS_UNKNOWN - unknown`
  - Both errors are subclasses of `Epics::Error`, not of `Epics::Error::TechnicalError`

### 3.1.1

- [FIX] `C54` on H005 requested the BTF service `REP` instead of `STM`. The German
  mapping is `STM | DE | camt.054 | ZIP`, and banks that follow it (e.g. GLS) rejected
  the request with `EBICS_INVALID_ORDER_TYPE`
- [FIX] `Z54` on H005 requested `EOP | XQRR` instead of `REP | CH | camt.054`, and `Z01`
  sent the service option `CH003GEN`, which the Swiss mapping doesn't define. Swiss banks
  (e.g. the ZKB test platform) rejected both with `EBICS_INVALID_ORDER_TYPE`
  - **Behaviour change:** `Z54` now returns all aggregate booking details. For the QR
    reference payments only (ZQR), pass `service_option: 'XQRR'`
  - Swiss banks also require the message version, e.g.
    `e.Z54(from, to, scope: 'CH', msg_name_version: '08')`
- [ENHANCEMENT] `container_type: false` leaves the `Container` out of an H005 download
  request, while `nil` keeps the order type's default (`ZIP`). The ZKB offers the pain.002
  status report in version 10 only without a container:
  `e.Z01(from, to, scope: 'CH', msg_name_version: '10', container_type: false)`

### 3.1.0

- [ENHANCEMENT] Verification of Payee (VoP) and the EDS (distributed electronic
  signature, German VEU). A credit transfer uploaded with VoP (`e.CCT(document,
  service_option: 'VOI', request_eds: true)` on H005) waits in the EDS until it is signed.
  - `VPZ` downloads the VoP status reports (pain.002): H005 `BTD REP/DE/VOP/pain.002/ZIP`,
    H004 order type `VPZ`.
  - `HVU` lists the orders waiting in the EDS, `HVD` returns the DataDigest and display
    file of one of them.
  - `HVE` signs and so releases an order, `HVS` cancels it. Both fetch the DataDigest via
    `HVD` first; pass `digest:` to sign only when it matches the digest you expect,
    otherwise `Epics::DataDigestMismatchError` is raised and nothing is sent.
  - The order is identified by a BTF service hash on H005 and by its order type on H004.

### 3.0.1

- [FIX] Upload order data was transmitted with all CR and LF removed, not as given. Any
  content hashed by the caller no longer matched, so container uploads (e.g. `CCS`, `CDS`,
  `C2S` with a `conxml` container whose `HashValue` covers the canonical pain message) were
  rejected by the bank, and line breaks inside text values were lost. As in 2.x, the order
  data is now sent unchanged and CR and LF are removed only to form the ES (electronic
  signature) hash, as EBICS specifies; the bank removes them the same way before verifying.
  This reverts the 3.0.0.rc1 entry "Upload order data is now normalized once"

### 3.0.0

- [FIX] H005 uploads were sent without `SignatureFlag` in `BTUOrderParams`, although they
  carry the user's ES (electronic signature), so banks treated them as orders
  to be authorised outside EBICS and some rejected them with `EBICS_INVALID_ORDER_TYPE`.
  `SignatureFlag` is now set by default, matching `OZHNN` on H004. Pass `request_eds: true`
  to spool the order into the EDS (distributed electronic signature, German VEU)
  when signatures are still missing, or `signature_flag: false` to omit the flag

### 3.0.0.rc2

- [FIX] A download spanning several segments returned only its first segment, so zipped
  downloads such as `C52` and `C53` raised `Zip::Error` and plain ones such as `STA` came
  back cut off without an error. The remaining segments are now requested in the transfer
  phase and the order data is decrypted once all segments are joined. A segmented response
  without a readable `NumSegments` raises `Epics::InvalidResponseError`
- [FIX] Truncated order data was inflated as far as it went and returned. It now raises
  `Epics::InvalidOrderDataError`, with the `Zlib` or `OpenSSL` error as its `cause`, and a
  negative receipt is sent instead of a positive one, so the bank does not consider a
  broken download as delivered

### 3.0.0.rc1

Major release adding EBICS 3.0 (H005) and EBICS 2.4 (H003) support, alongside a
rewrite of request building into builders/factories/handlers.

**Breaking changes**

- [BREAKING] Default key size for `Epics::Client.setup` raised from 2048 to 4096 bits
- [BREAKING] Removed internal accessors that were never intended as public API:
  `Client#a`, `#e`, `#x`, `#bank_x`, `#bank_e`, `#keys=`, `#x_509_certificate`,
  `#x_509_certificate_hash`, `#x_509_certificates_content`, `#header_request`, and the
  constants `Epics::Key`, `Epics::Signer`, `Epics::X509Certificate`,
  `Epics::HeaderRequest`, `Epics::XMLSIG`
- [BREAKING] `Client#keys` is now recomputed per call; mutating it no longer injects keys
- [BREAKING] On H005, `Client#HAA` and `Client#order_types` return an array of service
  hashes (`service_name`, `scope`, `service_option`, `container`, `msg_name`) instead of
  an array of order-type strings
- [BREAKING] `XEK`, `YCT` and `ZSR` raise `Epics::VersionSupportError` on H003/H004
  instead of `NotImplementedError`, matching every other version mismatch
- [BREAKING] `order_id:` is validated against the EBICS `OrderIDType` range (`A000` to
  `ZZZZ`). Values below `A000` rendered as e.g. `0002`, which violates the
  `[A-Z][A-Z0-9]{3}` pattern; they now raise `ArgumentError`. The protocol form
  (`order_id: 'A000'`) is accepted alongside the integer
- [BREAKING] Removed `Epics::Builders::MutableBuilder#add_receipt_code`, which emitted
  `ReceiptCode` inside `mutable` where the schema does not allow it. `ReceiptCode`
  belongs to `TransferReceipt`, which `TransferReceiptBuilder` already builds
- [BREAKING] Upload order data is now normalized once, on the way in, so the bytes
  hashed for the electronic signature are the bytes transmitted. Until 3.0 the digest
  was taken over the normalized document while the raw one was sent, which only
  verifies against banks that normalize before checking the ES
- [BREAKING] Passing only one date-range bound (e.g. `client.STA(from)`) silently
  omitted the range and fetched the bank's full retention window. Both bounds are
  mandatory within `DateRange`, so this now raises `ArgumentError`
- [BREAKING] Removed `Epics::Services::CryptService#sign`, which had no callers and
  disagreed with `#encrypt` on how an A005 signature is formed

**Fixes**

- [FIX] Loading a key file with the wrong passphrase raised `OpenSSL::PKey::PKeyError`
  about one time in 256, when the decrypted garbage happened to be padded correctly.
  Decryption now verifies it produced a PEM, so a wrong passphrase always raises
  `OpenSSL::Cipher::CipherError`
- [FIX] An unreadable certificate in an HPB response raised a bare
  `OpenSSL::X509::CertificateError`. It now raises `Epics::InvalidCertificateError`
  naming the HPB response as the source and keeping the OpenSSL message
- [FIX] `Response#signature_valid?` and `#public_digest_valid?` raised `NoMethodError`
  when the key they need was not loaded; they now raise `Epics::MissingKeyError` naming
  it. `#digest_valid?` no longer needs a key at all — it is a plain SHA-256 over the
  authenticated nodes
- [FIX] Removed the `container_flag:` order parameter, which emitted a `ContainerFlag`
  element that exists in no EBICS schema. The container is expressed by `Container`
  with a `containerType` attribute, which `container_type:` already emits
- [ENHANCEMENT] Added the H005-only order types `XEK` (account statements as PDF),
  `ZSR` (payment status reports) and `YCT` (multi-currency credit transfer). Their BTF
  mappings existed in the V3 factory but had no order class or client method
- [ENHANCEMENT] `XEK`, `ZSR`, `Z01`, `Z52`, `Z53` and `Z54` accept `scope:`,
  `service_option:`, `msg_name_version:` and `container_type:`. Defaults are unchanged;
  Swiss market practice requires a `Scope` and only `ZSR` sent one, so a bank-specific
  value can now be supplied without patching the gem
- [ENHANCEMENT] `C54` accepts `scope:`, `msg_name_version:` and `container_type:`, the
  same options as `C52` and `C53`; `C53` gained `container_type:`. The three camt
  retrievals now differ only in service name and message type
- [FIX] `save_keys` discarded any key-file entry it could not map to one of the five
  keyring slots, so a `host_id` that no longer matched the stored prefix destroyed the
  bank's public keys on save. Unrecognised entries are now carried through unchanged,
  and a warning names each one instead of the failure being swallowed
- [FIX] `XCT` sent the wrong order type: `CD1` on H003/H004 and the DTAZV service on
  H005, filing credit transfers as direct debits. It now sends `XCT` on H003/H004.
  EBICS 3.0 defines no counterpart for XCT, so on H005 it raises
  `Epics::VersionSupportError` rather than guessing a BTF service
- [FIX] The electronic signature over order data is again formed with line separators
  removed, matching 2.x. The refactor had signed the raw document, changing the ES for
  every upload
- [FIX] H005 `DataDigest` carried an RSA-PSS signature (256 bytes, non-reproducible)
  instead of the SHA-256 hash of the order data
- [FIX] `Response#business_error?` treated every `01`-prefixed return code as
  informational, reporting `011001` (negative acknowledgement) and `011101` (segment
  number not reached) as success. It now uses an explicit allow-list
- [FIX] `Time` and `DateTime` passed as date-range bounds rendered an `xs:dateTime`
  with a local offset into an `xs:date` element; they are now coerced to a date
- [FIX] `C52` requested no container on H005 while `Client#C52` always unzips the
  response, raising `Zip::Error`. `C52` and `C53` now default to a ZIP container and
  both accept `container_type:` to override it
- [FIX] `Epics::Client.setup` forwarded its block to `.new`, which yields before the
  keys are generated, so the block saw an empty keyring and anything touching it —
  `ini_letter`, `save_keys`, `INI`, `HIA` — failed. It now yields once the client is
  usable
- [FIX] `Epics::VersionSupportError` was raised as `raise Error, version, 'below'`,
  where the third argument is the backtrace, so the direction was dropped and the
  stack trace destroyed. 2.x-only order types on H005 now report "Support for versions
  below 3.0" and keep their trace

### 2.11.0

- [ENHANCEMENT] Added FUL order type (thanks to @scollon-pl)

### 2.10.0

- [ENHANCEMENT] Added X.509 certificates support for INI and HIA (thanks to @vnoviskyi)
- [ENHANCEMENT] Added Z01 order type (thanks to @Nymuxyzo)

### 2.9.0

- [ENHANCEMENT] Added HEV order type (thanks to @jplot)

### 2.8.0

- [ENHANCEMENT] Added BKA order type

### 2.7.0

- [ENHANCEMENT] Added FDL order type (thanks to @frantisekrokusek)
- [ENHANCEMENT] Added support for configuring locale and client/product name on initialization (thanks to @frantisekrokusek)

### 2.6.0

- [ENHANCEMENT] Added CIP order type (instant transfers)
- [ENHANCEMENT] Added gem metadata (thanks to @Nymuxyzo)

### 2.5.0

- [HOUSEKEEPING] Bump XML dependency requirements to more recent versions
- [HOUSEKEEPING] Bump bundler version to 2.5.19
- [HOUSEKEEPING] Bump ruby required version from 2.7 to 3.1
- [ENHANCEMENT] Request Header generation more generalized (thanks to @jplot)
- [ENHANCEMENT] Multi language support for initialization letter (thanks to @jplot)
- [ENHANCEMENT] Added support for WSS and C5N order types (thanks to @kostja93)

### 2.4.0

- [ENHANCEMENT]  Adds XE2 and XE3 order type (CCT and CDD for swiss banks)

### 2.3.0

- [ENHANCEMENT]  Adds Z52, Z53, Z54 order type (C52, C53, C54 for swiss banks)

### 2.2.0

- [ENHANCEMENT]  Adds C2S order type
- [HOUSEKEEPING] updates nokogiri dependency
- [HOUSEKEEPING] updates rexml dependency
- [HOUSEKEEPING] adds Ruby 3.3 to CI

### 2.1.2

- [BUGFIX] Fix order data encryption for OpenSSL 3

### 2.1.1

- [HOUSEKEEPING] update Bank public key initialization for OpenSSL 3

### 2.1.0

- [HOUSEKEEPING] updates Nokogiri dependencies
- [HOUSEKEEPING] updates Bundler dependency
- [HOUSEKEEPING] updates Gemfile bundler version
- [HOUSEKEEPING] Bump ruby required version from 2.6 to 2.7

### 2.0.0
- [BUGFIX] Add Openssl 3.0 support
- [BUGFIX] Update CDZ to download data, not upload it
- [BUGFIX] Support signature for keys later than 2048 bit
- [HOUSEKEEPING] Open rubyzip dependency to allow newer versions and update it
- [HOUSEKEEPING] Update supported ruby versions to 2.6+
- [HOUSEKEEPING] Update faraday, nokogiri, and development dependencies
- [HOUSEKEEPING] Remove JRuby test execution due to failing tests - needs to be re-added if required
- [ENHANCEMENT] Adds CRZ order type
- [ENHANCEMENT] Make date period optional for CDZ order type

### 1.8.1
- [BUGFIX] Remove masking of transport client errors

### 1.8.0

- [HOUSEKEEPING] updates faraday and rubyzip
- [HOUSEKEEPING] as a result: bump required ruby version to 2.4+

### 1.7.2

- [FEATURE] adds XCT order type (thanks to @punkle64)

### 1.7.1

- [HOUSEKEEPING] sets headers for requests to text/xml
- [HOUSEKEEPING] updates Nokogiri dependencies

### 1.7.0

- [ENHANCEMENT] adds CDB (thanks to @romanlehnert)
- [BUGFIX] fixes CCS order type and attribute (thanks to @gadimbaylisahil)
- [BUGFIX] make CDZ callable via client

### 1.6.0

- [BUGFIX] allow unstreamable zipfile handling
- [ENHANCEMENT] adds CDZ order type
- updates dependencies

### 1.5.2

- [COMPATIBILITY] be removing the `goyku` dependency we're more recilent against old versions of that gem
- [ENHANCEMENT] #order_type gives you more complete overview which order types to current client is entitled
  to use, there was already `HAA` which isn't as complete as this, which gets its info from `HTD`

### 1.5.1

- [ENHANCEMENT] some banks are not returning the order_id in the second upload phase, we now fetch it already
  from the first response to handle this different behaviour.
- [ENHANCEMENT] New order types: `AZV` (Auslandszahlungsverkehr). `CDS` and `CCS` for submitting SEPA credits/debits
  as SRZ (Service Rechen Zentrum)

### 1.5.0

- [ENHANCEMENT] support for fetching the C54 order type
- [ENHANCEMENT] Exceptions expose their internal code via `code`
- [HOUSEKEEPING] Added Ruby 2.4 compatibility
- [HOUSEKEEPING] Drop Ruby 2.0.0

### 1.4.1

- [ENHANCEMENT] support for fetching the VMK order type

### 1.4.0

- [ENHANCEMENT] STA without date range to fetch all statements which have not yet been fetched
- [ENHANCEMENT] HAC without date range to fetch all transaction logs which have not yet been fetched

### 1.3.1

- [ENHANCEMENT] make xpath namespaces explicit, so we can cover a wider
  rage of responses

### 1.3.0

- [BUGFIX] unzip C5X payloads
- [ENHANCEMENT] B2B direct debits

### 1.2.2

- [BUGFIX] HPB namespaces are unpredictable so be ignore them

### 1.2.1

- [BUGFIX] fixing wrong variable bind within `credit`, `debit` and `statements`

### 1.2.0

- [ENHANCEMENT] uploads will return both ebics_order_id and ebics_transaction_id

### 1.1.2

- [BUGFIX] missing require statements for `zlib`
- [BUGFIX] #16 `setup` tried to initialize wrong class

### 1.1.1

- [BUGFIX] CCT order was submited as CD1
- [BUGFIX] padding was calculated against the wrong block size
- [BUGFIX] double encoding of the signature

### 1.1.0

- [BUGFIX] Sending `Receipts` after downloading data, to circumvent download locks
- [BUGFIX] adding missing require statements
- adding HAC, HKD, C52 and C53 support
- less verbose object inspection for `Epics::Client`
- readme polishing

### 1.0.0

- first release

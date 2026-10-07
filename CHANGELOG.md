### Unreleased

- [FIX] A download spanning several segments returned only its first segment, so zipped
  downloads such as `C52` and `C53` raised `Zip::Error` and plain ones such as `STA` came
  back cut off without an error. The remaining segments are now requested in the transfer
  phase and the order data is decrypted once all segments are joined
- [FIX] Truncated order data was inflated as far as it went and returned. It now raises
  `Zlib::BufError` or `OpenSSL::Cipher::CipherError`, and a negative receipt is sent
  instead of a positive one, so the bank does not consider a broken download as delivered

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
- [BREAKING] Removed `Epics::Builders::MutableBuilder#add_receipt_code`, which emitted
  `ReceiptCode` inside `mutable` where the schema does not allow it. `ReceiptCode`
  belongs to `TransferReceipt`, which `TransferReceiptBuilder` already builds
- [FIX] Removed the `container_flag:` order parameter, which emitted a `ContainerFlag`
  element that exists in no EBICS schema. The container is expressed by `Container`
  with a `containerType` attribute, which `container_type:` already emits
- [ENHANCEMENT] Added the H005-only order types `XEK` (account statements as PDF),
  `ZSR` (payment status reports) and `YCT` (multi-currency credit transfer). Their BTF
  mappings existed in the V3 factory but had no order class or client method
- [BREAKING] `XEK`, `YCT` and `ZSR` raise `Epics::VersionSupportError` on H003/H004
  instead of `NotImplementedError`, matching every other version mismatch
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
- [BREAKING] `order_id:` is validated against the EBICS `OrderIDType` range (`A000` to
  `ZZZZ`). Values below `A000` rendered as e.g. `0002`, which violates the
  `[A-Z][A-Z0-9]{3}` pattern; they now raise `ArgumentError`. The protocol form
  (`order_id: 'A000'`) is accepted alongside the integer

- [FIX] `XCT` sent the wrong order type: `CD1` on H003/H004 and the DTAZV service on
  H005, filing credit transfers as direct debits. It now sends `XCT` on H003/H004.
  EBICS 3.0 defines no counterpart for XCT, so on H005 it raises
  `Epics::VersionSupportError` rather than guessing a BTF service
- [FIX] The electronic signature over order data is again formed with line separators
  removed, matching 2.x. The refactor had signed the raw document, changing the ES for
  every upload
- [BREAKING] Upload order data is now normalized once, on the way in, so the bytes
  hashed for the electronic signature are the bytes transmitted. Until 3.0 the digest
  was taken over the normalized document while the raw one was sent, which only
  verifies against banks that normalize before checking the ES
- [FIX] H005 `DataDigest` carried an RSA-PSS signature (256 bytes, non-reproducible)
  instead of the SHA-256 hash of the order data
- [FIX] `Response#business_error?` treated every `01`-prefixed return code as
  informational, reporting `011001` (negative acknowledgement) and `011101` (segment
  number not reached) as success. It now uses an explicit allow-list
- [BREAKING] Passing only one date-range bound (e.g. `client.STA(from)`) silently
  omitted the range and fetched the bank's full retention window. Both bounds are
  mandatory within `DateRange`, so this now raises `ArgumentError`
- [FIX] `Time` and `DateTime` passed as date-range bounds rendered an `xs:dateTime`
  with a local offset into an `xs:date` element; they are now coerced to a date
- [FIX] `C52` requested no container on H005 while `Client#C52` always unzips the
  response, raising `Zip::Error`. `C52` and `C53` now default to a ZIP container and
  both accept `container_type:` to override it
- [BREAKING] Removed `Epics::Services::CryptService#sign`, which had no callers and
  disagreed with `#encrypt` on how an A005 signature is formed
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

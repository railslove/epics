### 2.1.0

- [HOUSEKEEPING] updates Nokogiri dependencies
- [HOUSEKEEPING] updates Bundler dependency
- [HOUSEKEEPING] updates Gemfile bundler version

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

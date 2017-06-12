### 1.4.1

  * [ENHANCEMENT] support for fetching the VMK order type

### 1.4.0

  * [ENHANCEMENT] STA without date range to fetch all statements which have not yet been fetched
  * [ENHANCEMENT] HAC without date range to fetch all transaction logs which have not yet been fetched

### 1.3.1

  * [ENHANCEMENT] make xpath namespaces explicit, so we can cover a wider
  rage of responses

### 1.3.0

  * [BUGFIX] unzip C5X payloads
  * [ENHANCEMENT] B2B direct debits

### 1.2.2

  * [BUGFIX] HPB namespaces are unpredictable so be ignore them

### 1.2.1

  * [BUGFIX] fixing wrong variable bind within `credit`, `debit` and `statements`

### 1.2.0

  * [ENHANCEMENT] uploads will return both ebics_order_id and ebics_transaction_id

### 1.1.2

  * [BUGFIX] missing require statements for `zlib`
  * [BUGFIX] #16 `setup` tried to initialize wrong class

### 1.1.1

  * [BUGFIX] CCT order was submited as CD1
  * [BUGFIX] padding was calculated against the wrong block size
  * [BUGFIX] double encoding of the signature

### 1.1.0

  * [BUGFIX] Sending `Receipts` after downloading data, to circumvent download locks
  * [BUGFIX] adding missing require statements
  * adding HAC, HKD, C52 and C53 support
  * less verbose object inspection for `Epics::Client`
  * readme polishing

### 1.0.0

  * first release

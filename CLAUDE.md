# CLAUDE.md

Guidance for working in this repository.

## What this is

`epics` is a Ruby gem implementing the [EBICS](https://www.ebics.org/) protocol
(Electronic Banking Internet Communication Standard) — a bank-communication
standard used mainly in Germany/France/Switzerland. It handles the key
initialization handshake (INI / HIA / HPB), signs requests, and exchanges
payment and statement order types with a bank's EBICS server.

- Pure library gem (no Rails). Entry point: `require "epics"`.
- Supports **EBICS 2.5 (H004, default)** and **EBICS 3.0 (H005, opt-in)**.
- License LGPL-3.0. Published to RubyGems as `epics`.

## Commands

```bash
bin/setup            # bundle install
bundle exec rspec    # run the full test suite
bundle exec rspec spec/client_spec.rb          # single file
bundle exec rspec spec/client_spec.rb:42       # single example
bin/console          # irb with the gem loaded (pry available)
```

- Ruby: developed on **3.3.7** (`.tool-versions`); CI matrix runs 3.2 / 3.3 / 3.4 / 4.0.
- `required_ruby_version >= 3.1`.
- CI is Semaphore (`.semaphore/semaphore.yml`) — just `bundle install` + `rspec`.
- No linter/formatter is configured; match surrounding style.

## Architecture

Everything is namespaced under the `Epics` module (`Ebics` is an alias).
`lib/epics.rb` is the manifest: it `require`s every file explicitly (no
autoloading) and defines protocol constants (`EBICS_PROTOCOLS`, `DEFAULT_VERSION`).

### The three layers

1. **`Epics::Client`** (`lib/epics/client.rb`) — the public API and the only
   object users instantiate. Holds credentials + RSA keys, exposes one method
   per order type (`STA`, `CCT`, `CDD`, `HPB`, `HTD`, …) plus convenience
   wrappers (`credit`, `debit`, `statements`). Owns the Faraday `connection`
   and key encryption/decryption (AES-256-CBC over a passphrase).

2. **Order classes** (`lib/epics/<order>.rb`, e.g. `sta.rb`, `cct.rb`) — one
   small class per EBICS order type. Each subclasses `GenericRequest`
   (downloads) or `GenericUploadRequest` (uploads) and typically only overrides
   `#header` to declare `order_type`, `order_attribute`, and params. This is
   the dominant pattern — to add an order type, copy the closest sibling.

3. **Request builders + middleware**
   - `generic_request.rb` / `generic_upload_request.rb` / `header_request.rb` —
     build the EBICS XML envelope via Nokogiri.
   - `middleware/xmlsig.rb` — Faraday middleware that signs the outgoing XML
     (`Epics::Signer` + `signer.rb`) before it leaves.
   - `middleware/parse_ebics.rb` — Faraday middleware that wraps every response
     in `Epics::Response` and raises `Epics::Error::TechnicalError` /
     `BusinessError` on non-OK return codes.

### Transaction flow

`Client#download` / `#upload` (near the bottom of `client.rb`) run the
multi-step EBICS handshake: an initialization POST returns a `transaction_id`,
followed by transfer/receipt POSTs. `download_and_unzip` additionally unpacks
the ZIP payload (used by camt orders C52/C53/C54, Z-types, BKA…). Response
parsing lives in `response.rb`; RSA/key handling in `key.rb`.

### H004 vs H005 (important)

The gem defaults to H004. H005 is selected via `Epics::Client.new(..., version: :h005)`.

- `client.protocol` / `namespace` / `protocol_version` / `revision` / `h005?`
  derive from the configured version.
- Under H005 there is **no flat OrderTypes list** — transactions are
  **BTF services** (`btf.rb`, `btf_mapping.rb`, `Client#services`). Generic
  transfer is `BTU` (upload, replaces FUL) / `BTD` (download, replaces FDL).
- Many classic order methods branch: e.g. `CCT`/`CDD`/`STA`/`C53` call
  `btf_upload` / `btf_download` when `h005?`. When touching an order type,
  check whether it needs an H005 branch.
- X.509 certificate support (`x_509_certificate.rb`, `letter/ini_with_certs.erb`)
  is part of the H005 path.

### INI letter

`letter_renderer.rb` renders the paper initialization letter from
`lib/letter/*.erb`, localized via `lib/letter/locales/*.yml` (de/en/fr, i18n).

## Tests

- RSpec, config in `spec/spec_helper.rb` (`--require spec_helper` via `.rspec`).
- **WebMock** stubs all HTTP — tests never hit a real bank.
- Real EBICS responses live as fixtures in `spec/fixtures/xml/`; RSA keys/certs
  in `spec/fixtures/*.pem` and `*.key`. Compare XML with `equivalent-xml`'s
  `be_equivalent_to` matcher (namespace/whitespace-insensitive).
- H005-specific coverage is in `spec/h005_client_spec.rb`.
- Helpers/shared setup in `spec/support/`.

## Conventions

- One file per order type, named after the 3-letter EBICS code, lowercased
  (`cct.rb` → `Epics::CCT`). Register new files in `lib/epics.rb`.
- Keep order classes minimal — push shared logic into the `Generic*` base
  classes, not into individual order types.
- `# frozen_string_literal: true` is used on newer files; keep it when editing them.
- Bump `Epics::VERSION` (`lib/epics/version.rb`) and update `CHANGELOG.md` for releases.

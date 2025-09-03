[![Build Status](https://railslove.semaphoreci.com/badges/epics/branches/master.svg?style=shields)](https://railslove.semaphoreci.com/branches/c29225c5-5b7e-4a90-8ac8-22d1aa28efcf)
[![Gem Version](https://badge.fury.io/rb/epics.svg)](http://badge.fury.io/rb/epics)

# Epics

EPICS is a ruby implementation of the [EBICS](https://www.ebics.org/) (Electronic Banking Internet
Communication Standard).

It supports EBICS 2.5.

The client supports the complete initialization process comprising INI, HIA and HPB including the
INI letter generation. It offers support for the most common download and upload order types
(STA HAA HTD HPD PTK HAC HKD BKA C52 C53 C54 CD1 CDB CDD CCT VMK FDL FUL).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'epics'
```

Or install it yourself as:

    $ gem install epics

## Getting started

In case you are new to EBICS, you'll have to complete an initialization process with
your bank. Epics can help you generate all necessary keys and directly store
them for later use. But first you'll have to lift some contractually work with your
bank.

Once the paperwork is done, your bank should provide you with:

- _a_ URL to their EBICS Server
- _a_ HOST ID
- _a_ PARTNER ID
- _n_ User IDs (depends on your bank and needs)

Take these parameters and start setting up an UserID (repeat this for every user you want to initialize):

```ruby
e = Epics::Client.setup("my-super-secret", "https://ebics.sandbox", "EBICS_HOST_ID", "EBICS_USER_ID", "EBICS_PARTNER_ID")
```

To use the keys later, just store them in a file

```ruby
e.save_keys("/home/epics/my.key")
# or store the json elsewhere, but store it! for gods sake :D
```

It is really **important** to keep your keys around, once your user has been initialized
you'll have to start over when you loose the keys!

Submit the keys to your bank:

```ruby
e.INI # sends the signature key
e.HIA # sends the encryption and authentication keys
```

The next step is to print the INI letter and post it to your bank:

```ruby
e.save_ini_letter( 'My Banks Name', "/home/epics/ini.html" )
```

Open the generated HTML file in your favorite browser and print it (skipping
header and footer sounds like a solid setting here ;). In case you're having difficulties
with the encoding, try forcing your browser to use UTF-8.

Put the INI letter in an envelope and mail it to your bank!

Done! ... Well not completely :)

Once the bank confirms that your user is completely initialized, you'll have to
download the public keys of your bank:

```ruby
### see below for client creation
e.HPB
```

Then again, save the keys or store the json somewhere safe.

You're now ready to go. Maybe try:

```ruby
e.HAA
```

To get a list of all supported order types.

## Need help? Having questions?

We have many years of experience in developing innovative applications for the finance sector and
integrating applications with financial institutions. - you might want to have a look at our
[portfolio](http://www.railslove.com/portfolio)
**If you need help we are happy to provide consulting or development services. Contact us:
[team@railslove.com](mailto:team@railslove.com)**

## Usage

### Create a client

```ruby
# read the keys from a file
e = Epics::Client.new(File.open('/tmp/my.key'), 'passphrase', 'url', 'host', 'user', 'partner')

# or provide a string hoding the key data
keys = File.read('/tmp/my.key')

e = Epics::Client.new(keys, 'passphrase', 'url', 'host', 'user', 'partner')
```

### Client Configuration

You can choose to configure some default values like this

```ruby
# For default values see `lib/epics.rb`
e = Epics::Client.new(keys, 'passphrase', 'url', 'host', 'user', 'partner', locale: :fr, product_name: 'Mon Epic Client EBICS')
```

## Features

### Initialization

- INI (Sends the public key of the electronic signature.)
- HIA (Sends the public authentication (X002) and encryption (E002) keys.)

### Downloads

Currently this EPICS implementation supports the following order types:

- HPB (fetch your bank's public keys)
- STA (statements in MT940 format)
- HAA (available order types)
- HTD (user properties and settings)
- HPD (the available bank parameters)
- PTK (customer usage report in text format)
- HAC (customer usage report in xml format)
- VMK (customer usage report in xml format)
- ... more coming soon

Example:

```ruby
puts e.STA('2014-09-01', '2014-09-11')
# result is a MT940 feed

:20:1
:25:/PL12124012551111000015237873
:28C:00152
:60F:C081130PLN000000002535,03
:61:0810021002DN000000001273,23N641NONREF
:86:641^00PRZELEW MI¨DZYBANKOWY BETA/^34000
^3019401076^38PL54194010765205871800000000
^20wynagrodzenie z tytulu umow^21y o prac e
^32BANKA MONIKA
^62PODCHORAZYCH 16/1580-298 GD^63ANSK
:61:0810021002DN000000001287,40N641NONREF
:86:641^00PRZELEW MI¨DZYBANKOWY BETA/^34000
^3010201909^38PL74102019090000310200475772
^20wynagrodzenie z tytulu umow^21y o prac e
^32SZCZACHOR DOROTA
^62RATAJA 13B/1083-032 PSZCZOL^63KI
```

### Uploads

- CD1 (Uploads a SEPA Direct Debit document of type COR1)
- CDB (Uploads a SEPA Direct Debit document of type B2B)
- CDD (Uploads a SEPA Direct Debit document of type CORE)
- CCT (Uploads a SEPA Credit document)
- ... more coming soon

Example:

```ruby
puts e.CD1("i-am-PAIN-xml")
# res is a the transaction id and id of the order

# if the XML is a file in your FS, read it first and give if epics to consume
puts e.CD1(File.read("/where/the/xml/is/stored.xml"))

```

### Lazy Mode

Once you have a client, go ahead and start playing! There are 3 convenience methods
that are hiding some strange names from you:

- debit( _xml_ ) (submits a PAIN.008.003.02 document via CDD)
- credit( _xml_ ) (submits a pain.001.003.03 document)
- statements( _from_, _to_ ) (fetches an account statement via STA)

If you need more sophisticated EBICS order types, please read the next section
about the supported functionalities.

## Issues and Feature Requests

[Railslove](http://railslove.com) is commited to provide the best developer tools for integrating
with financial institutions. Epics is one of our many tools and services.
If you are missing some features or something is not working as expected please create an issue.

## Supported Banks

This gem provides a full implementation of the Electronic Banking Internet Communication Standard
and works with any bank that supports this standard. Please ask your bank if they support EBICS and
what order types are available.

Besides EBCIS being a standard, some server implementations are slighty different.
But most banks use the same EBICS server implementations. Commonly used and supported by Epics are:

- Business-Logics EBICS, Banking-Server
- Travic Corporate

Used for example by the following tested institutions:

- Handelsbank
- Deutsche Bank
- Commerzbank
- Kreissparkasse Mayen
- Postbank
- Sozialbank
- Sparkassen
- Volksbanken Raiffeisenbanken
- Hypo Vereinsbank
- BAWAG P.S.K. (AT)
- Bank Frick (LI)
- BNP Paribas (FR)

Is Epics working with your institution? Please help us to grow this list of supported banks:

## Development

For development purposes, you may want to use a proxy server in order to have a convenient look into request and response data.
To do so, it's sufficient to define `http_proxy` in your environment.
Also you may want to disable SSL verification - simply set `EPICS_VERIFY_SSL` to `"false"`.

For example:

```
http_proxy=localhost:8080
EPICS_VERIFY_SSL=false
```

## Links

- [ebics.de](http://www.ebics.de/)
- [EBICS specification](http://www.ebics.de/index.php?id=30)
- [Common Integrative Implementation Guide to Supplement the EBICS Specification (pdf)](http://www.ebics.de/fileadmin/unsecured/specification/implementation_guide_DE/EBICS_Common_IG_basiert_auf_EBICS_2.5.pdf)
- [Die Deutsche Kreditwirtschaft](http://www.die-deutsche-kreditwirtschaft.de/)

## Contributing
Railslove has a [Contributor License Agreement (CLA)](https://github.com/railslove/epics/blob/master/CONTRIBUTING.md) which clarifies the intellectual property rights for contributions from individuals or entities. To ensure every developer has signed the CLA, we use [CLA  Assistant](https://cla-assistant.io/).

After checking out the repo, run `bin/setup` to install dependencies. 
Then, run `rspec` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

0. Contact team@railslove.com for information about the CLA
1. Fork it ( https://github.com/[my-github-username]/epics/fork )
2. Run `bin/setup`
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## Contribution Credits

- [@punkle64](https://github.com/punkle64) \
  for adding XCT order type
- [@romanlehnert](https://github.com/romanlehnert) \
  for adding CDB order type
- [@gadimbaylisahil](https://github.com/gadimbaylisahil) \
  for fixing CCS order type and attribute
- you, for contributing too!

---

2014-2022 - built with love by [Railslove](http://railslove.com) and released under the [GNU LESSER GENERAL PUBLIC LICENSE](https://github.com/railslove/epics/blob/master/LICENSE.txt). We have built quite a number of FinTech products. If you need support we are happy to help. Please contact us at team@railslove.com.

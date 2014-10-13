[![Build Status](https://magnum.travis-ci.com/railslove/epics.svg?token=EhFJyZWe1sxdBDmF2bzC&branch=master)](https://magnum.travis-ci.com/railslove/epics)

# Epics

EPICS is a ruby implementation of the [EBICS](http://www.ebics.org/) (Electronic Banking Internet Communication Standard)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'epics'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install epics


## Getting started

In case your new to EBICS, you'll have to complete a initialization process with
your bank. Epics can help you to generate all the necessary keys and directly store
them for later use.

```ruby
e = Epics.initialize("my-super-secret", "https://ebics.sandbox", "SIZBN001", "EBIX", "EPICS")
```

This will be plain JSON, holding your authentication, encryption and signature key
encrypted with AES-256.

To use the keys later, just store them in a file

```ruby
e.save_keys("/home/epics/my.key")
# or store the json elsewhere, but store it! for gods sake :D
```

It is really __important__ to keep your keys around, once your user has been initialized
you'll have to start over when you loose the keys!

The next step is to print the INI letter and sending it to your bank:

```ruby
e.save_ini_letter( 'My Banks Name', "/home/epics/ini.html" )
```

Open the generated HTML file in your favorite browser and print it out (skipping
header and footer sounds like a solid setting here ;)

Put the INI letter in a envelope and mail it to your bank!

Done!

## Usage

### Create a client

```ruby
# read the keys from a file
e = Epics::Client.new(File.open('/tmp/my.key'), 'passphrase', 'url', 'host', 'user', 'partner')

# or provide a string hoding the key data
keys = File.read('/tmp/my.key')

e = Epics::Client.new(keys, 'passphrase', 'url', 'host', 'user', 'partner')
```

## Initialization

* INI (Sends the public key of the electronic signature.)
* HIA (Sends the public authentication (X002) and encryption (E002) keys.)

### Downloads

Currently this EPICS implementation supports the following order types:

* HPB (fetch your bank's public keys)
* STA (statements in MT940 format)
* HAA (available order types)
* HTD (user properties and settings)
* HPD (the available bank parameters)
* PKT (customer usage report in text format)
* ... more coming soon

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

* CD1 (Uploads a SEPA Direct Debit document of type COR1)
* CDD (Uploads a SEPA Direct Debit document of type CORE)
* CCT (Uploads a SEPA Credit document)
* ... more coming soon

Example:

```ruby
puts e.CD1("i-am-a-PAIN-xml-file")
# res is a the transaction id of the order
```

## Supported Banks

* Sofortbank
* Deutsche Bank

## Contributing

1. Fork it ( https://github.com/[my-github-username]/epics/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

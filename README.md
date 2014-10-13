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

## Usage

### Create a client

```ruby
# read the keys from a file
e = Epics::Client.new(File.open('/tmp/my.key'), 'passphrase', 'url', 'host', 'user', 'partner')

# or provide a string hoding the key data
keys = File.read('/tmp/my.key')

e = Epics::Client.new(keys, 'passphrase', 'url', 'host', 'user', 'partner')
```

### Initialization

In case your new to EBICS, you'll have to complete a initialization process with
your bank. When create a `Epics::Client` and the keyfile isn't present, we'll create
the needed keys for you. You can then call `INI` and `HIA` to transfer the public
key information to you can. In addition its required to send the key information
via a second channel, this is what `ini_letter` is for. It creates a html file
containing all the needed information.

* INI (Sends the public key of the electronic signature.)
* HIA (Sends the public authentication (X002) and encryption (E002) keys.)

1. create the INI/HIA Letter

`
e.ini_letter("Bank Name", "/tmp.ini.html")
`

2. Print the file and send it to your bank :)


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

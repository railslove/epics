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

In case you are new to EBICS, you'll have to complete a initialization process with
your bank. Epics can help you to generate all the necessary keys and directly store
them for later use, but first you'll have to to lift some contractually work with your
bank.

Once the paperwork is done, your bank should provide you with:

* a URL to their EBICS Server
* a HOST ID
* a PARTNER ID
* n User IDs (this depends on the bank and your needs)

Take this parameters and start setting up one UserID (repeat this for every user
you want to initialize):

```ruby
e = Epics::Client.setup("my-super-secret", "https://ebics.sandbox", "SIZBN001", "EBIX", "EPICS")
```

To use the keys later, just store them in a file

```ruby
e.save_keys("/home/epics/my.key")
# or store the json elsewhere, but store it! for gods sake :D
```

It is really __important__ to keep your keys around, once your user has been initialized
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

Open the generated HTML file in your favorite browser and print it out (skipping
header and footer sounds like a solid setting here ;) In case your having difficulties
with the encoding, try forcing your browser to use UTF-8.

Put the INI letter in a envelope and mail it to your bank!

Done! ... Well not completly :)

Once the bank confirms that your user is completely initialized. You'll have to
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

## Usage

### Create a client

```ruby
# read the keys from a file
e = Epics::Client.new(File.open('/tmp/my.key'), 'passphrase', 'url', 'host', 'user', 'partner')

# or provide a string hoding the key data
keys = File.read('/tmp/my.key')

e = Epics::Client.new(keys, 'passphrase', 'url', 'host', 'user', 'partner')
```

### Lazy Mode

Once you have a client, go ahead and start playing! There are 3 convinence methods
that are hiding some strange names from you:

* debit( _xml_ ) (submits a PAIN.008.003.02 document via CDD)
* credit( _xml_ ) (submits a pain.001.003.03 document)
* statements( _from_, _to_ ) (fetches an account statement via STA)

If you need more sophisticated EBICS order types, please read the next section
about the supported functionalities.

## Features

### Initialization

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
* HAC (customer usage report in xml format)
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

Besides EBCIS being a Standard, some server implementations are slighty
different. Is Epics working with your institution? Please help us to grow
this list of supported banks:

* Sofortbank
* Deutsche Bank
* Sparkasse KölnBonn

## Contributing

0. Contact team@railslove.com for information about howto CLA
1. Fork it ( https://github.com/[my-github-username]/epics/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request




made with love by [railslove](http://www.railslove.com)

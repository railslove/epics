[![Build Status](https://travis-ci.org/railslove/epics.svg?branch=master)](https://travis-ci.org/railslove/epics)
[![Gem Version](https://badge.fury.io/rb/epics.svg)](http://badge.fury.io/rb/epics)

# Epics

EPICS is a ruby implementation of the [EBICS](http://www.ebics.org/) (Electronic Banking Internet Communication Standard)

The client supports the complete initialization process comprising INI, HIA and HPB including the INI letter generation. It offers support for the most common download and upload order types (STA HAA HTD HPD PKT HAC HKD C52 C53 C54 CD1 CDD CCT)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'epics'
```

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


## Need help? Having questions? 

We have many years of experience in developing innovative applications for the finance sector and integration application with financial institutions. - you might want to have a look at our [portfolio](http://www.railslove.com/portfolio)   
__If you need help we are happy to provide consulting or development services. Contact us: [team@railslove.com](mailto:team@railslove.com)__


## Usage

### Create a client

```ruby
# read the keys from a file
e = Epics::Client.new(File.open('/tmp/my.key'), 'passphrase', 'url', 'host', 'user', 'partner')

# or provide a string hoding the key data
keys = File.read('/tmp/my.key')

e = Epics::Client.new(keys, 'passphrase', 'url', 'host', 'user', 'partner')
```


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

### Lazy Mode

Once you have a client, go ahead and start playing! There are 3 convinence methods
that are hiding some strange names from you:

* debit( _xml_ ) (submits a PAIN.008.003.02 document via CDD)
* credit( _xml_ ) (submits a pain.001.003.03 document)
* statements( _from_, _to_ ) (fetches an account statement via STA)

If you need more sophisticated EBICS order types, please read the next section
about the supported functionalities.


## Issues and Feature Requests

[Railslove](http://railslove.com) is commited to provide the best developer tools for integrating with financial institutions. Epics is one of our many tools and services. 
If you are missing some features or something is not working as expected please create an issue. 



## Supported Banks

This gem provides a full implementation of the Electronic Banking Internet Communication Standard and works with any bank that supports this standard. Please ask your bank if they support EBICS and what order types are available. 

Besides EBCIS being a standard, some server implementations are slighty different. 
Is Epics working with your institution? 
Please help us to grow this list of supported banks:

* Sofortbank
* Deutsche Bank
* Sparkasse KölnBonn


## Links

* [ebics.de](http://www.ebics.de/)
* [EBICS specification](http://www.ebics.de/index.php?id=30)
* [Common Integrative Implementation Guide to Supplement the EBICS Specification (pdf)](http://www.ebics.de/fileadmin/unsecured/specification/implementation_guide_DE/EBICS_Common_IG_basiert_auf_EBICS_2.5.pdf)
* [Die Deutsche Kreditwirtschaft](http://www.die-deutsche-kreditwirtschaft.de/) 


## Contributing

0. Contact team@railslove.com for information about the CLA
1. Fork it ( https://github.com/[my-github-username]/epics/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


------------
2014 - built with love by [Railslove](http://railslove.com) and released under the [GNU LESSER GENERAL PUBLIC LICENSE](https://github.com/railslove/epics/blob/master/LICENSE.txt). We have built quite a number of FinTech products. If you need support we are happy to help. Please contact us at team@railslove.com.

# Epics

EPICS is a ruby implementation of the EBICS protocol

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
e = Epics::Client.new('/path/to/keyfile', 'passphrase', 'url', 'host', 'user', 'partner')

```

### Downloads

Currently this EPICS implementation supports the following order types:

* STA (statements in MT940 format)
* HAA (available order types)
* HTD (user properties and settings)
* HPD (the available bank parameters)
* PKT (customer usage report in text format)
* ... more coming soon

Addionally you can use `HPB` to fetch your bank's public keys

```ruby
res = e.STA('2014-09-01', '2014-09-11')
# res is a MT940 feed

```

### Initialization (coming soon)

* INI (Sends the public key of the electronic signature.)
* HIA (Sends the public authentication (X002) and encryption (E002) keys.)

### Uploads

* CD1 (Uploads a SEPA Direct Debit document of type COR1)
* CDD (Uploads a SEPA Direct Debit document of type CORE)
* CCT (Uploads a SEPA Credit document)
* ... more coming soon

```ruby
res = e.CD1("i-am-a-PAIN-xml-file")
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

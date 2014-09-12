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

### HPB

```ruby

hpb = Epics::HPB.new.to_xml
user_key = Epics::Key(...)

signer = Epics::Signer.new(hpb, user_key)

signer.digest!.sign!.doc.to_xml

```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/epics/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

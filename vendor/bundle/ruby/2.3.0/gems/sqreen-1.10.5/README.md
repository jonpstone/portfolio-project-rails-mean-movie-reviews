# Sqreen

Auto protection for you application.

Copyright (c) 2015 Sqreen. All Rights Reserved.
Please refer to our terms for more information: https://www.sqreen.io/terms.html

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sqreen'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sqreen

## Configuration

The only required parameter is your application's `token`.

### By file
- for Rails:
```shell
  $ echo token: your_token > /path/to/RailsApp/config/sqreen.yml
```
- for anything else:
```shell
      $ echo token: your_token > ~/sqreen.yml
    ```

### By environment:
    ```shell
          $ export SQREEN_TOKEN=your_token
    ```

The following can be set:

*file*      | *environment*
------------|-------------
token       | SQREEN_TOKEN
url         | SQREEN_URL
verbosity   | SQREEN_VERBOSITY
local_rules | SQREEN_RULES

SQREEN_RULES allows the agent to use rules that do not come from the server, but
from a local file.

## Usage

TODO: Write usage instructions here

## Development

```shell
$ gem install bundler
$ bundle
```

Check that everything is all right:
```shell
$ bundle exec rake test
```

Use `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sqreen/RubyAgent. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

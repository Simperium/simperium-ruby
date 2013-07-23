simperium-ruby
==============
Simperium is a simple way for developers to move data as it changes, instantly and automatically. This is the Ruby library. You can [browse the documentation](http://simperium.com/docs/ruby/).

You can [sign up](http://simperium.com) for a hosted version of Simperium. There are Simperium libraries for [other languages](https://simperium.com/overview/) too.

This is not yet a full Simperium library for parsing diffs and changes. It's a wrapper for our [HTTP API](https://simperium.com/docs/http/) intended for scripting and basic backend development.

Testing
-------

Before running tests you will need to hunt down and install some prerequisites:

- [Bundler](http://gembundler.com) (should be as easy as `gem install bundler`)
- [MongoDB](http://www.mongodb.org)

### First Run 

To run the tests, clone the repository and `bundle install` to install all of
the dependencies.

```bash
$> git clone https://github.com/simperium/simperium-ruby
$> bundle install
```

Go to simperium.com and register a new app. Set your shell's environment
variables `SIMPERIUM_CLIENT_TEST_APPNAME` and `SIMPERIUM_CLIENT_TEST_APIKEY` to
your new app's "App ID" and "API Key" respectively.

Thereafter running tests should only require:

```bash
$> bundle exec rake test
```

### License
The Simperium Ruby library is available for free and commercial use under the MIT license.
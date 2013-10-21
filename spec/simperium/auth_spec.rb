require 'minitest/pride'
require 'minitest/spec'
require 'minitest/autorun'
require 'mocha/setup'
require 'webmock/minitest'

require 'rest_client'
require 'json'

require 'simperium/auth'

describe Simperium::Auth, '#initialize' do
  it "raises an ArgumentError with no appname" do
    proc {
      Simperium::Auth.new(nil, '123456')
    }.must_raise ArgumentError
  end

  it "raises an ArgumentError with no api_key" do
    proc {
      Simperium::Auth.new('blazing-saddles', nil)
    }.must_raise ArgumentError
  end

  describe "setting the host" do
    it "sets the host argument as the host" do
      auth = Simperium::Auth.new('blazing-saddles', '123456', 'override_arg.simperium.com')

      auth.instance_variable_get(:@host).must_equal 'override_arg.simperium.com'
    end

    it "sets the ENV VAR as the host" do
      ENV.stubs(:[]).with('SIMPERIUM_AUTHHOST').returns('override_env.simperium.com')
      auth = Simperium::Auth.new('blazing-saddles', '123456')

      auth.instance_variable_get(:@host).must_equal 'override_env.simperium.com'
    end

    it "sets a default host" do
      auth = Simperium::Auth.new('blazing-saddles', '123456')

      auth.instance_variable_get(:@host).must_equal 'auth.simperium.com'
    end
  end
end

describe Simperium::Auth, '#create' do
  before do
    response = '{"username": "1382355902@foo.com", "access_token": "bf096b290d174402896522cf89b3c5", "userid": "5b4e0569270381b10fabb92b1f5f8fc3"}'

    stub_request(:post, "https://auth.simperium.com/1/blazing-saddles/create/").
      with(:body => {
             "client_id" => "123456",
             "password"  => "password",
             "username"  => "1382355902@foo.com" }).
      to_return(:status => 200, :body => response, :headers => {})
  end

  it "returns a token for the new user" do
    auth = Simperium::Auth.new('blazing-saddles', '123456')

    auth.create("1382355902@foo.com", 'password').must_equal 'bf096b290d174402896522cf89b3c5'
  end
end

describe Simperium::Auth, '#authorize' do
  before do
    response = '{"username": "1382355902@foo.com", "access_token": "d3dcbeda5a58410cb1cf9a7faf3060", "userid": "5b4e0569270381b10fabb92b1f5f8fc3"}'

    stub_request(:post, "https://auth.simperium.com/1/blazing-saddles/authorize/").
      with(:body => {"password"=>"password", "username"=>"1382355902@foo.com"},
           :headers => {'Content-Length'=>'47', 'X-Simperium-Api-Key'=>'123456'}).
      to_return(:status => 200, :body => response, :headers => {})
  end

  it "authorizes the user" do
    auth = Simperium::Auth.new('blazing-saddles', '123456')

    auth.authorize("1382355902@foo.com", 'password').must_equal 'd3dcbeda5a58410cb1cf9a7faf3060'
  end
end

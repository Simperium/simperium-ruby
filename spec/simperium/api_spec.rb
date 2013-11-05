require 'spec_helper'

require 'simperium'
require 'simperium/api'

describe Simperium::Api, '#method_missing?' do
  let(:api) { Simperium::Api.new('blazing-saddles', '123456') }

  it "instantiates the Simperium::Bucket that matches the symbol" do
    api.todo.must_be_instance_of Simperium::Bucket
    api.todo.instance_variable_get(:@bucket).must_equal :todo
  end

  it "caches the Simperium::Bucket" do
    bucket = api.todo

    api.instance_variable_get(:@cache)[:todo].must_equal bucket
  end

  it "returns an instance of SPUser"
  it "caches the SPUser"

  it "ignores setters" do
    (api.todo = "something").wont_be_instance_of Simperium::Bucket
  end
end

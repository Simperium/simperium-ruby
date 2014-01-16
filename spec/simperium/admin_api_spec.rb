require 'spec_helper'

require 'simperium/api'
require 'simperium/admin_api'

describe Simperium::AdminApi, '#as_user' do
  it "instantiates a Simperium::Api with the keys to act as a user" do
    admin_api = Simperium::AdminApi.new('blazing-saddles', '123456')

    api = admin_api.as_user('portfolio@happyinspector.com')

    api.must_be_instance_of(Simperium::Api)
    api.app_id.must_equal('blazing-saddles')
    api.token.must_equal('123456')
    api.options.values.must_include('portfolio@happyinspector.com')
  end
end

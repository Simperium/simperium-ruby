require 'spec_helper'

require 'simperium'

describe Simperium::SPUser do
  before do
    response = '{"username": "simperium@simperium.com", "userid": "1678e04aa2e08bf8d5ca20deac1234"}'
    stub_request(:get, "https://api.simperium.com/1/battleship/spuser").
      with(:headers => { :'X-Simperium-Token' => '789012' }).
      to_return(:body => response)
  end

  describe "getting user information" do
    let(:spu) { Simperium::SPUser.new('battleship', '789012') }

    it "fetches the userid" do
      spu.userid.must_equal "1678e04aa2e08bf8d5ca20deac1234"
    end

    it "fetches the username" do
      spu.username.must_equal "simperium@simperium.com"
    end
  end
end

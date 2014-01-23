require 'spec_helper'

require 'simperium/bucket'

describe Simperium::Bucket do
  let(:bucket) { Simperium::Bucket.new('blazing', '123456', 'bucketname') }

  it "stores a default host" do
    bucket.host.must_equal 'api.simperium.com'
  end

  it "can configure the host" do
    bucket = Simperium::Bucket.new('blazing', '123456', 'bucketname', :host => 'api2.simperium.com' )

    bucket.host.must_equal 'api2.simperium.com'
  end
end

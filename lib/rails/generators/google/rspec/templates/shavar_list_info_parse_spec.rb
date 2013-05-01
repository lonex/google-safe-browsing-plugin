require 'spec_helper'

describe "Faraday Middleware list info parsing" do

  before(:all) do
    @parser = Faraday::Response::SafeBrowsingUpdateParser.new
  end
  
  it "should parse sample test data one" do
    resp = <<-END_OF_SAMPLE
n:1200
i:googpub-phish-shavar
u:cache.google.com/first_redirect_example
u:cache.google.com/second_redirect_example
sd:1,2
i:acme-white-shavar
u:cache.google.com/second_redirect_example
ad:1-2,4-5,7
sd:2-6
    END_OF_SAMPLE

    r = @parser.parse resp
    r.next.should eq(1200)
    r.rekey.should be_nil
    r.reset.should be_nil
    
    phish_list = r.get_list('googpub-phish-shavar')
    phish_list[:u].should eq(["cache.google.com/first_redirect_example", "cache.google.com/second_redirect_example"])
    phish_list[:sd].should eq([1, 2])
    phish_list[:ad].should be_empty
    
  end
  
  it "should stop parsing if reset is in the response" do
    resp = <<-END_OF_SAMPLE
n:1200
r:pleasereset
i:goog-phish-shavar
u:cache.google.com/first_redirect_example
    END_OF_SAMPLE
  
    r = @parser.parse resp
    r.next.should eq(1200)
    r.reset.should be_true
    r.has_lists?.should be_false
  end
  
end

require File.expand_path('../../spec_helper', __FILE__)

describe "The URL canonicalizer should work" do
  
  include Google::UrlCanonicalizer
  
  it "should unescape hex encoding" do
    url = 'http://host/%25%32%35'
    apply(url).should eq('http://host/%25')
  end
  
  it "should unescape hex encoding case two" do
    url = 'http://host/%25%32%35%25%32%35'
    apply(url).should eq('http://host/%25%25')
  end

  it "should unescape hex encoding case three and percent escape" do
    url = 'http://host/%%%25%32%35asd%%'
    apply(url).should eq('http://host/%25%25%25asd%25%25')
  end
  
  it "should unescape hex encoding case four" do
    url = 'http://%31%36%38%2e%31%38%38%2e%39%39%2e%32%36/%2E%73%65%63%75%72%65/%77%77%77%2E%65%62%61%79%2E%63%6F%6D/'
    apply(url).should eq('http://168.188.99.26/.secure/www.ebay.com')
  end
  
  it "should unescape hex case five" do
    url = "http://\x01\x80.com/"
    apply(url).should eq("http://80.com/")
  end
  
  it "should remove the # fragment" do
    url = 'http://www.evil.com/blah#frag'
    apply(url).should eq('http://www.evil.com/blah')
  end
  
  it "should keep the port number if any" do
    url = 'http://www.gotaport.com:1234/'
    apply(url).should eq('http://www.gotaport.com:1234/')
  end
  
  it "should add trailing slash if missing" do
    url = 'http://www.yahoo.com'
    apply(url).should eq('http://www.yahoo.com/')
  end

  it "should remove consecutive slash" do
    url = "http://host.com//twoslashes?more//slashes"
    apply(url).should eq('http://host.com/twoslashes?more//slashes')
  end

end
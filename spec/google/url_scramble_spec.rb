require File.expand_path('../../spec_helper', __FILE__)

describe "The GoogleSafeBrowsing URL suffix/prefix" do
  
  it "should work with url with query params" do
    url = 'http://a.b.com/1/2.html?param=1'
    host_keys, url_set = Google::UrlScramble.gen(url)
    host_keys.sort!
    url_set.sort!

    url_set[0].should eq('a.b.com/')
    url_set[1].should eq('a.b.com/1')
    url_set[2].should eq('a.b.com/1/2.html')
    url_set[3].should eq('a.b.com/1/2.html?param=1')
    url_set[4].should eq('b.com/')
    url_set[5].should eq('b.com/1')
    url_set[6].should eq('b.com/1/2.html')
    url_set[7].should eq('b.com/1/2.html?param=1')
    
    host_keys.second.should eq('b.com/')
    host_keys.first.should eq('a.b.com/')
  end
  
  it "should work with url domain that has levels of subdomains" do
    url = 'http://a.b.c.d.e.f.com/1.html'

    host_keys, url_set = Google::UrlScramble.gen(url)
    host_keys.sort!
    url_set.sort!

    host_keys.first.should eq('e.f.com/')
    host_keys.second.should eq('f.com/')
    host_keys.size.should eq(2)
    
    url_set[0].should eq('a.b.c.d.e.f.com/')
    url_set[1].should eq('a.b.c.d.e.f.com/1.html')
    url_set[2].should eq('c.d.e.f.com/')
    url_set[3].should eq('c.d.e.f.com/1.html')
    url_set[4].should eq('d.e.f.com/')
    url_set[5].should eq('d.e.f.com/1.html')
    url_set[6].should eq('e.f.com/')
    url_set[7].should eq('e.f.com/1.html')
    url_set[8].should eq('f.com/')
    url_set[9].should eq('f.com/1.html')
    
  end
  
  it "should work with url without path and query" do
    url = 'http://www.google.com/'

    host_keys, url_set = Google::UrlScramble.gen(url)
    host_keys.sort!
    url_set.sort!

    host_keys.first.should eq('google.com/')
    host_keys.second.should eq('www.google.com/')
    host_keys.size.should eq(2)
    
    url_set[0].should eq('google.com/')
    url_set[1].should eq('www.google.com/')
    
  end

  it "should work with domain is ip address" do
    url = 'http://23.32.45.123/a?q=1'
    host_keys, url_set = Google::UrlScramble.gen(url)
    host_keys.sort!
    url_set.sort!

    host_keys.first.should eq('23.32.45.123/')
    host_keys.size.should eq(1)
    
    url_set[0].should eq('23.32.45.123/')
    url_set[1].should eq('23.32.45.123/a')
    url_set[2].should eq('23.32.45.123/a?q=1')

  end

end
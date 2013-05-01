require 'spec_helper'

describe "Parse the binary data parsing" do

  include Google::SafeBrowsingParser

  def read_shavar_download_file file
    resp = File.read(file, :encoding => 'ASCII-8BIT')
  end
  
  it "should read add chunk binary data" do
    file = File.expand_path('../bin_sample_1.data', __FILE__)
  
    resp = read_shavar_download_file file
    adds, subs = parse_shavar_list(resp)
    
    add = adds.first
    add[:chunk_num].should eq(113601)
    add[:hash_len].should eq(4)
    add[:chunk_len].should eq(6246)
    data = add[:chunk_data]
    data['3c8fbb74'].should eq(["87c99352", "3a71cbc0", "421e54f4"])
    data['1487ee7d'].should eq([])

    add = adds.last
    add[:chunk_num].should eq(113656)
    add[:hash_len].should eq(4)
    add[:chunk_len].should eq(850)
    data = add[:chunk_data]
    data['c21ddace'].should eq([])
    data['b3b36f29'].should eq(['5d472258'])

  end

  it "should read add chunk binary data" do
    file = File.expand_path('../bin_sample_2.data', __FILE__)
  
    resp = read_shavar_download_file file
    adds, subs = parse_shavar_list(resp)
    
    sub = subs.first
    sub[:chunk_num].should eq(112801)
    sub[:hash_len].should eq(4)
    sub[:chunk_len].should eq(157)
    data = sub[:chunk_data]
    data['f48787fc'][108559].should eq(["37f0e2d6"])

    sub = subs.last
    sub[:chunk_num].should eq(112960)
    sub[:hash_len].should eq(4)
    sub[:chunk_len].should eq(210)
    data = sub[:chunk_data]
    data['812324f0'][111330].should eq(["981f1261"])
  end

end  
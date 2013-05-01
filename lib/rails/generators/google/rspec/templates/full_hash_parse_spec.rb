require 'spec_helper'

describe "Parse full length hash response from GoogleSafeBrowsing" do
  
  include Google::SafeBrowsingParser

  def read_full_length_hash_file file
    resp = File.read(file, :encoding => 'ASCII-8BIT')
  end

  def display_list full_list
    full_list.keys.each do |list|
      puts "List #{list}"
      puts "    Full length hash:"
      full_list[list].keys.each do |add_chunk_num|
        puts "       Add chunk num: #{add_chunk_num}"
        full_list[list][add_chunk_num].each do |full_hash|
          puts "             full hash: #{full_hash}"
        end
      end
      puts "========="
    end
  end
  
  it "should capture single full length hash" do
    resp = read_full_length_hash_file File.expand_path('../full_hash_response_0.data', __FILE__)
    full_list = parse_full_hash_entries resp
    full_list[:'goog-malware-shavar'][113869].should eq(['34f0021bea5c18b405cf9a279f91555100efc4edfb8909d074eab584fd702826'])
  end

  it "should capture 2 full length hashes" do
    resp = read_full_length_hash_file File.expand_path('../full_hash_response_1.data', __FILE__)
    full_list = parse_full_hash_entries resp
    full_list[:'goog-malware-shavar'][113869].should eq(
       ['746e32e9833b573db34c8044f6020b9379632558c4267d811cd8db70016300b7', 
        'ad1701117dd7dcd36d8add796f0ba16c3e1fb22a0154883c9eac14f53e5a063d'])

    # display_list full_list
  end

  it "should capture full length hash for both malware and phishing" do
    resp = read_full_length_hash_file File.expand_path('../full_hash_response_2.data', __FILE__)
    full_list = parse_full_hash_entries resp
    full_list[:'goog-malware-shavar'][113423].should eq(['b3e357a66e2130ecb4afcb0fcefd32ff5e536c9fd3219681c045bcd48b89be3e'])
    full_list[:'googpub-phish-shavar'][238266].should eq(['5b3583c05bdaeb39718b1d865f012663fe22f9e8de01ef0ede8d4653d87e766a'])
    
  end

  it "should capture full length hash for more complex match" do
    resp = read_full_length_hash_file File.expand_path('../full_hash_response_3.data', __FILE__)
    full_list = parse_full_hash_entries resp
    full_list[:'goog-malware-shavar'][113423].should eq(['b3e357a66e2130ecb4afcb0fcefd32ff5e536c9fd3219681c045bcd48b89be3e'])
    full_list[:'googpub-phish-shavar'][238266].should eq([
      '5b3583c05bdaeb39718b1d865f012663fe22f9e8de01ef0ede8d4653d87e766a',
      '7e930bdaee322d25e4f422cc6dc688f50b1920127d8a604efd5e5ffb18d78284'])
  end

end
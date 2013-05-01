require File.expand_path('../../spec_helper', __FILE__)

describe "Form correct chunk nums for GoogleSafeBrowsing data update request" do

  include Google::SafeBrowsingUpdateHelper
  
  it "should form the string for empty chunk ids" do
    ids = []
    s = gen_chunk_nums_string(ids)
    s.should eq('')
  end
  
  it "should form the string for single chunk id" do
    ids = [1]
    s = gen_chunk_nums_string(ids)
    s.should eq('1')
  end
  
  it "should form the string for 1-2 range ids" do
    ids = [1,2]
    s = gen_chunk_nums_string(ids)
    s.should eq('1-2')
  end
  
  it "should form the string for 5-6 range and then 1 integer" do
    ids = [5,6,11]
    s = gen_chunk_nums_string(ids)
    s.should eq('5-6,11')
  end
  
  it "should form the string for 1 integer and then a range" do
    ids = [5,11,12]
    s = gen_chunk_nums_string(ids)
    s.should eq('5,11-12')
  end

  it "should form the string for 3 integers" do
    ids = [5,11,21]
    s = gen_chunk_nums_string(ids)
    s.should eq('5,11,21')
  end
  
  it "should form the string for 1 integer followed by range followed by 1 integer" do
    ids = [1, 3, 4, 5, 11]
    s = gen_chunk_nums_string(ids)
    s.should eq('1,3-5,11')
  end

  it "should form the string for the mix of integers and ranges" do
    ids = [1, 3, 4, 5, 11, 21, 22, 23, 31]
    s = gen_chunk_nums_string(ids)
    s.should eq('1,3-5,11,21-23,31')
  end

  it "should form the string for ids starting with range and ending with range" do
    ids = [1, 2, 3, 11, 21, 22, 23, 31, 32]
    s = gen_chunk_nums_string(ids)
    s.should eq('1-3,11,21-23,31-32')
  end
      
end
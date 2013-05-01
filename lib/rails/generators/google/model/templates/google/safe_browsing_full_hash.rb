module Google
  class SafeBrowsingFullHash < ActiveRecord::Base
    belongs_to :list, :class_name => "Google::SafeBrowsingList", :foreign_key => "google_safe_browsing_list_id"
  
    attr_accessible :add_chunk_num, :value, :google_safe_browsing_list_id
  end  
end
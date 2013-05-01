module Google
  class SafeBrowsingRedirectUrl < ActiveRecord::Base
    
    belongs_to :list, :class_name => "Google::SafeBrowsingList", :foreign_key => "google_safe_browsing_list_id"
    attr_accessible :url, :order, :download_state, :last_download_at, :google_safe_browsing_list_id
    before_create :set_other_attrs
    before_update :set_download_attr
    
    COMPLETED ||= 'completed'
    
    scope :for_url_and_list_id, lambda { |url, list_id|
      where(url_hash: SafeBrowsingRedirectUrl.url_hash_key(url), google_safe_browsing_list_id: list_id)
    } 

    def set_other_attrs
      ord = Google::SafeBrowsingRedirectUrl.maximum(:order)
      self.order = ord.nil?? 1 : ord + 1
      self.url_hash = SafeBrowsingRedirectUrl.url_hash_key(self.url)
      set_download_attr
    end

    def set_download_attr
      if !self.download_state.blank? && self.download_state != COMPLETED
        self.download_attempts ||= 0
        self.download_attempts += 1
      end
    end
    
    class << self
      def url_hash_key url_str
        Digest::MD5.hexdigest(url_str)
      end
    end
    
  end  
end
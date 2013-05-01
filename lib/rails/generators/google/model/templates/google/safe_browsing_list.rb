module Google
  class SafeBrowsingList < ActiveRecord::Base
    
    MalwareList ||= 'goog-malware-shavar'
    PhishList   ||= 'googpub-phish-shavar'
  
    attr_accessible :prefix
 
    has_many :shavars, :class_name => "Google::SafeBrowsingShavar", :foreign_key => "google_safe_browsing_list_id", :dependent => :destroy
    has_many :redirect_urls, :class_name => "Google::SafeBrowsingRedirectUrl", :foreign_key => "google_safe_browsing_list_id", :dependent => :destroy
    has_many :full_hashes, :class_name => "Google::SafeBrowsingFullHash", :foreign_key => "google_safe_browsing_list_id", :dependent => :destroy

    class << self
      
      def valid_list? list_name
        [MalwareList, PhishList].include?(list_name.to_s)
      end
      
      def malware_list
        @malware_list_obj ||= find_by_name MalwareList
      end
      
      def phishing_list
        @phishing_list_obj ||= find_by_name PhishList
      end
      
      def list_by_name name
        if valid_list?(name.to_s)
          if malware_list.name == name.to_s
            malware_list
          elsif phishing_list.name == name.to_s
            phishing_list
          end
        else
          nil
        end
      end
      
    end
  end
end
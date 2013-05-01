class CreateGoogleSafeBrowsingRedirectUrls < ActiveRecord::Migration
  
  class << self
    def up
      create_table :google_safe_browsing_redirect_urls do |t|
        t.string :url, :limit => 2047
        t.string :url_hash        
        t.integer :order
        t.integer :google_safe_browsing_list_id
        t.string :download_state
        t.integer :download_attempts
        t.datetime :last_download_at
        t.timestamps
      end
    
      add_index :google_safe_browsing_redirect_urls, :url_hash, :name => 'index_redirect_url_hashes'
      add_index :google_safe_browsing_redirect_urls, :order, :name => 'index_redirect_urls_order'
    
    end
  
    def down
      drop_table :google_safe_browsing_redirect_urls
    end
    
  end
end

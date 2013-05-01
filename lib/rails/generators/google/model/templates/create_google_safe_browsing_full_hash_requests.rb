class CreateGoogleSafeBrowsingFullHashRequests < ActiveRecord::Migration
  
  class << self
    def up
      create_table :google_safe_browsing_full_hash_requests do |t|
        t.string :prefix
        t.string :state
        t.integer :attempts
        t.datetime :created_at
        t.datetime :requested_at
      end
    
      add_index :google_safe_browsing_full_hash_requests, :prefix, :name => 'index_hash_prefix'
    
    end
  
    def down
      drop_table :google_safe_browsing_full_hash_requests
    end

  end
end

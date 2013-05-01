class CreateGoogleSafeBrowsingShavar < ActiveRecord::Migration
  
  class << self
    def up
      create_table :google_safe_browsing_shavars do |t|
        t.integer :chunk_num
        t.string :chunk_type, :limit => 1  # "a" or "s"
        t.string :host_key
        t.integer :add_chunk_num  # Only for sub shavar data, add shavar data will have it as NULL
        t.string :prefix
        t.integer :google_safe_browsing_list_id  # malware or phishing
      end

      add_index :google_safe_browsing_shavars, [:chunk_type, :host_key], :name => 'index_chunk_type_host'
      add_index :google_safe_browsing_shavars, [:chunk_type, :host_key, :prefix], :name => 'index_chunk_type_host_prefix'
      add_index :google_safe_browsing_shavars, [:chunk_type, :add_chunk_num, :host_key, :prefix], :name => 'index_add_chunk_host_prefix'
    
      add_index :google_safe_browsing_shavars, \
                [:google_safe_browsing_list_id, :chunk_type, :chunk_num, :host_key, :add_chunk_num, :prefix], :unique => true, :name => 'index_chunk_host_prefix'
    end

    def down
      drop_table :google_safe_browsing_shavars
    end
  end
  
end

class CreateGoogleSafeBrowsingFullHashes < ActiveRecord::Migration

  class << self
    def up
      create_table :google_safe_browsing_full_hashes do |t|
        t.string :value   # 32 Bytes
        t.integer :add_chunk_num
        t.integer :google_safe_browsing_list_id
        t.timestamps
      end
    
      add_index :google_safe_browsing_full_hashes, :value, :name => 'index_full_hashes'
    
    end

    def down
      drop_table :google_safe_browsing_full_hashes
    end
  end
end

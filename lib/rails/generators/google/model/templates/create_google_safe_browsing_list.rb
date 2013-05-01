class CreateGoogleSafeBrowsingList < ActiveRecord::Migration

  class << self
    def up
      create_table :google_safe_browsing_lists do |t|
        t.string :name
      end
    end
  
    def down
      drop_table :google_safe_browsing_lists
    end
  end
    
end

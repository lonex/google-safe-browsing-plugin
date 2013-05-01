class CreateGoogleFunctions < ActiveRecord::Migration

  class << self
    def up
      create_table :google_functions do |t|
        t.string :name, :limit => 255
        t.integer :version
        t.timestamp :next_updated_at
        t.timestamps
      end
    end
  
    def down
      drop_table :google_functions
    end
    
  end
end
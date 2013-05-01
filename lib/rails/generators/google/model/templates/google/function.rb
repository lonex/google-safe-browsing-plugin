module Google
  class Function < ActiveRecord::Base
    GoogleSafeBrowsing ||= 'GoogleSafeBrowsing'
    attr_accessible :name, :version, :next_updated_at
  end
end

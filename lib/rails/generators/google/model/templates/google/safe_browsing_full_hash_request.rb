module Google
  class SafeBrowsingFullHashRequest < ActiveRecord::Base
    before_save :set_other_attrs
    
    attr_accessible :prefix, :state, :attempts, :requested_at
    
    COMPLETED ||= 'completed'
    
    def set_other_attrs
      if !self.state.blank? && self.state != COMPLETED
        self.attempts ||= 0
        self.attempts += 1
      else
        self.attempts = nil
      end
    end
    
  end  
end
# To capture the GSB Update payload
module Google
  class SafeBrowsingUpdate
    
    # 
    # BODY      = [(REKEY | MAC) LF] NEXT LF (RESET | (LIST LF)+) EOF
    # NEXT      = "n:" DIGIT+                               # Minimum delay before polling again in seconds
    # REKEY     = "e:pleaserekey"
    # RESET     = "r:pleasereset"
    # LIST      = "i:" LISTNAME [MAC] (LF LISTDATA)+
    # LISTNAME  = (LOALPHA | DIGIT | "-")+                  # e.g. "goog-phish-sha128"
    # MAC       = "," (LOALPHA | DIGIT)+
    # LISTDATA  = ((REDIRECT_URL | ADDDEL-HEAD | SUBDEL-HEAD) LF)+
    # REDIRECT_URL = "u:" URL [MAC]
    # URL       = Defined in RFC 1738
    # ADDDEL-HEAD  = "ad:" CHUNKLIST
    # SUBDEL-HEAD  = "sd:" CHUNKLIST
    # CHUNKLIST = (RANGE | NUMBER) ["," CHUNKLIST]
    # NUMBER    = DIGIT+                                    # Chunk number >= 1
    # RANGE     = NUMBER "-" NUMBER
    # 
    
    attr_accessor :next, :rekey, :reset
    attr_reader :lists
    attr_accessor :current_list
    
    def set_current_list list_name
      @current_list = list_name.to_s.to_sym
      @lists ||= {}
      # :u is download urls
      # :sd is sub del
      # :ad is add del
      @lists[current_list] ||= { :u => [], :sd => [], :ad => [] }
    end
    
    def has_lists?
      @lists != nil
    end
    
    def get_list list_name
      @lists[list_name.to_s.to_sym]
    end
    
    def get_current_list
      @lists[current_list]
    end
    
    def get_redirect_urls list_name
      name = list_name.to_s.to_sym
      if @lists && @lists[name] && !@lists[name][:u].blank?
        @lists[name][:u]
      else
        []
      end
    end
    
    def get_ad_chunk_ids list_name
      name = list_name.to_s.to_sym
      if @lists && @lists[name] && !@lists[name][:ad].blank?
        @lists[name][:ad]
      else
        []
      end
    end
    
    def get_sd_chunk_ids list_name
      name = list_name.to_s.to_sym
      if @lists && @lists[name] && !@lists[name][:sd].blank?
        @lists[name][:sd]
      else
        []
      end
    end
   
    
  end
end
require 'faraday'

module Google
  class SafeBrowsingClient
    
    include Google::SafeBrowsingUpdateHelper
    
    attr_accessor :headers
  
    CLIENT  ||= 'api'
    API_KEY ||= Google::CONFIG['api_key']
    APP_VER ||= Google::CONFIG['app_ver']
    P_VER   ||= Google::CONFIG['p_ver']
  
    SEMI_COLON ||= ';'
    COLON      ||= ':'
    NL ||= %Q(\n)
    
    FULL_HASH_TIMEOUT = 2 # secs
    
    def initialize
      @headers = {
        :'User-Agent'    => 'Faraday Ruby Client'
      }
    end

    def api_server
      'https://safebrowsing.clients.google.com'
    end
  
    #
    # goog-malware-shavar
    # goog-regtest-shavar
    # goog-whitedomain-shavar
    # googpub-phish-shavar
    #
    def list_url
      '/safebrowsing/list?client=%s&apikey=%s&appver=%s&pver=%s' % [CLIENT, API_KEY, APP_VER, P_VER]
    end
    
    def download_url
      '/safebrowsing/downloads?client=%s&apikey=%s&appver=%s&pver=%s' % [CLIENT, API_KEY, APP_VER, P_VER]
    end  

    def full_hash_url
      '/safebrowsing/gethash?client=%s&apikey=%s&appver=%s&pver=%s' % [CLIENT, API_KEY, APP_VER, P_VER]
    end

    #
    #       resp = <<-END_OF_SAMPLE
    # n:1200
    # i:googpub-phish-shavar
    # u:cache.google.com/first_redirect_example
    # u:cache.google.com/second_redirect_example
    # sd:1,2
    # i:acme-white-shavar
    # u:cache.google.com/second_redirect_example
    # ad:1-2,4-5,7
    # sd:2-6
    #       END_OF_SAMPLE
    #       
    #       parser = Faraday::Response::SafeBrowsingUpdateParser.new
    # r = parser.parse resp
    # 
    def shavar_data_update list_name, options = {}
      conn = Faraday.new(url: api_server, headers: headers) do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::SafeBrowsingUpdateParser
        builder.adapter ::Faraday.default_adapter
      end
      
      request_body = download_data_request_body(list_name)
      
      r = conn.post do |req|
        req.url download_url
        req.body = request_body
      end

      if successful_status_code?(r.status)
        r.body
      else
        process_error_response(r.status)
      end
    end
    
    # 
    # To get shavar chunk data from the redirect url
    #
    def chunk_data redirect_url, options = {}
      url = 'https://' + redirect_url if /\Ahttps?/ !~ redirect_url
      
      conn = Faraday.new(headers: headers) do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.adapter ::Faraday.default_adapter
      end

      r = conn.post do |req|
        req.url url
      end

      if successful_status_code?(r.status)
        r.body
      else
        process_error_response(r.status)
      end

    end
    
    # 
    # hash_prefixes: ['5b3583c0', 'b3e357a6']
    # @return 
    #     # { 'goog-malware-shavar' (list_name) 
    #      => {
    #          :add_chunk_num1 => [full_hash0, full_hash1, ...]
    #          :add_chunk_num2 => [full_hash0]
    #         }
    # }
    #
    def full_hash hash_prefixes
      conn = Faraday.new(url: api_server, headers: headers) do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.adapter ::Faraday.default_adapter
      end
      
      request_body = full_hash_request_body hash_prefixes
      
      r = conn.post do |req|
        req.url full_hash_url
        req.body = request_body 
        req.options[:timeout] = FULL_HASH_TIMEOUT
      end
            
      if successful_status_code?(r.status)
        SafeBrowsingParser.parse_full_hash_entries r.body
      else
        process_error_response(r.status)
      end
    end
    
    # 
    # s;200
    # googpub-phish-shavar;a:1-3,5,8:s:4-5
    # acme-white-shavar;a:1-7:s:1-2
    # 
    def download_data_request_body list_name
      gen_list_request(list_name)
    end
    
    def gen_list_request list
      list = SafeBrowsingList.where(name: list).first
      s = StringIO.new("")
      s << list.name << SEMI_COLON
      add_chunk_ids = gen_chunk_nums_string(
                          SafeBrowsingShavar.add_chunk_nums_for_list(list.name).map(&:chunk_num))
      sub_chunk_ids = gen_chunk_nums_string(
                          SafeBrowsingShavar.sub_chunk_nums_for_list(list.name).map(&:chunk_num))
      
      s << SafeBrowsingShavar::CHUNK_TYPE_ADD << COLON << add_chunk_ids unless add_chunk_ids.blank?
      s << COLON if !add_chunk_ids.blank? && !sub_chunk_ids.blank?
      s << SafeBrowsingShavar::CHUNK_TYPE_SUB << COLON << sub_chunk_ids unless sub_chunk_ids.blank?
      s << NL
      s.string
    end
    
    # 
    # BODY       = HEADER LF PREFIXES EOF
    # HEADER     = PREFIXSIZE ":" LENGTH
    # PREFIXSIZE = DIGIT+         # Size of each prefix in bytes
    # LENGTH     = DIGIT+         # Size of PREFIXES in bytes
    # 
    # The prefixes should all have the same length of bytes
    #
    def full_hash_request_body prefixes
      return "" if prefixes.empty?
      
      prefix_size = prefixes.first.size / 2
      
      s = StringIO.new("")
      s << prefix_size.to_s << ":"
      s << (prefix_size * prefixes.size).to_s << NL
      s << pack_hash_prefix(prefixes, prefix_size)
      s.string
    end
    
    def pack_hash_prefix prefixes, prefix_size
      s = StringIO.new("")
      prefixes.each do |pre|
        s << [pre].pack("H#{prefix_size*2}")
      end
      s.string
    end
    
    def process_error_response status
      case status.to_s
      when /\A204/
        raise Error::NoContent
      when /\A4/
        raise Error::InvalidRequest
      when /\A5/
        raise Error::ServiceUnavailable
      else
        raise Error::UnknownError
      end
    end

    def successful_status_code?(status_code)
      status_code.to_s == '200'
    end
    
  end
end
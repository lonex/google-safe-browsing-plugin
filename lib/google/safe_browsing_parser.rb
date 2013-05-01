module Google
  module SafeBrowsingParser
    extend self
    
    ADD ||= SafeBrowsingShavar::CHUNK_TYPE_ADD
    SUB ||= SafeBrowsingShavar::CHUNK_TYPE_SUB
    
    ADD_SUB_HEAD ||= /(?<add_sub>a|s):(?<chunk_num>\d+):(?<hash_len>\d+):(?<chunk_len>\d+)(\n)/
    FULL_HASH_HEAD ||= /(?<rekey>e:pleaserekey)|((?<list>[-_\w]+):(?<chunk_num>\d+):(?<chunk_len>\d+))(\n)/
    
    CHUNKNUM_SIZE = HOST_KEY_SIZE = 4 # Bytes

    FULL_HASH_SIZE = 32 # Bytes, 256 bit
    
    #
    # @params str A clob of characters returned from the redirect download url
    # @returns Two arrays of shavar list data decoded: one for ADD, the other for SUB
    # 
    # The shavar list data has the following structure
    # For ADD
    # { :chunk_num => 343243, :hash_len => 4, :chunk_len => 4343,
    #   :chunk_data => {
    #                    :host_key_one => [prefix0, prefix1, ...],
    #                    :host_key_two => []
    #                  }
    # }
    # 
    # For SUB
    # { :chunk_num => 343243, :hash_len => 4, :chunk_len => 4343,
    #   :chunk_data => {
    #                    :host_key_one => { 
    #                                       :add_chunknum_one => [prefix0, prefix1, ...],
    #                                       :add_chunknum_two => []
    #                                     }
    #                    :host_key_two => {
    #                                       :add_chunknum_three => [prefix0, prefix1, ...],
    #                                       :add_chunknum_four => []
    #                                     }
    #                  }
    # }
    #
    def parse_shavar_list str, test_mode = false
      adds = []; subs = []
      scanner = StringScanner.new(str)
            
      count = 0; scanner.pos = 0
      while !(head = scanner.scan_until(ADD_SUB_HEAD)).nil?
        if test_mode && count > 0
          break
        end
        
        count += 1
        m = ADD_SUB_HEAD.match head
        chunk_num, hash_len, chunk_len = m[:chunk_num].to_i, m[:hash_len].to_i, m[:chunk_len].to_i
        pointer = 0; chunk_data = []

        while pointer < chunk_len
          chunk_data << scanner.get_byte
          pointer += 1
        end

        if m[:add_sub] == 'a'
          data_arr = parse_add_data(chunk_data, hash_len)
        elsif m[:add_sub] == 's'
          data_arr = parse_sub_data(chunk_data, hash_len)
        end
          
        obj = {
            chunk_num: chunk_num,
            hash_len:  hash_len,
            chunk_len: chunk_len,
            chunk_data: data_arr
          }

        if m[:add_sub] == ADD
          adds << obj
        elsif m[:add_sub] == SUB
          subs << obj
        end
        
      end
      
      Rails.logger.info "Total # of ADD/SUB section is #{count}, #{adds.size} adds, #{subs.size} subs"
      
      [adds, subs]
    end
    
    
    def parse_add_data byte_arr, hash_len
      ret = {}
      total_chars = 0
      pointer = 0
      while pointer < byte_arr.size
        host_key = parse_host_key byte_arr[pointer...pointer+HOST_KEY_SIZE]
        total_chars += HOST_KEY_SIZE
        pointer += HOST_KEY_SIZE
        ret[host_key] ||= []
        count = parse_count_number byte_arr[pointer]
        pointer += 1
        total_chars += 1
        
        if count > 0
          sub_count = 0
          while sub_count < count
            ret[host_key] << parse_hash_prefix(byte_arr[pointer...pointer+hash_len], hash_len)
            total_chars += hash_len
            pointer += hash_len
            sub_count += 1
          end
        end
      end
      
      ret
    end
    
    def parse_sub_data byte_arr, hash_len
      ret = {}
      total_chars = 0
      pointer = 0
      while pointer < byte_arr.size
        host_key = parse_host_key byte_arr[pointer...pointer+HOST_KEY_SIZE]
        total_chars += HOST_KEY_SIZE
        pointer += HOST_KEY_SIZE
        count = parse_count_number byte_arr[pointer]
        total_chars += 1
        pointer += 1

        ret[host_key] ||= {}
        if count > 0
          sub_count = 0
          while sub_count < count
            add_chunknum = byte_arr[pointer...pointer+CHUNKNUM_SIZE].join('').unpack('L>').first
            pointer += CHUNKNUM_SIZE; total_chars += CHUNKNUM_SIZE
            ret[host_key][add_chunknum] ||= []
            ret[host_key][add_chunknum] << parse_hash_prefix(byte_arr[pointer...pointer+hash_len], hash_len)
            pointer += hash_len; total_chars += hash_len
            sub_count += 1
          end
        else
          add_chunknum = byte_arr[pointer...pointer+CHUNKNUM_SIZE].join('').unpack('L>').first
          ret[host_key][add_chunknum] = []
          pointer += CHUNKNUM_SIZE; total_chars += CHUNKNUM_SIZE
        end
        
      end
      
      ret
    end
    
    def parse_host_key char_arr
      char_arr.join('').unpack('H8').first
    end
    
    def parse_count_number char
      char.unpack('C').first
    end
    
    def parse_hash_prefix char_arr, hash_len
      char_arr.join('').unpack("H#{hash_len*2}").first
    end
    
    #
    # Returns
    # { 'goog-malware-shavar' (list_name) 
    #      => {
    #          :add_chunk_num1 => [full_hash0, full_hash1, ...]
    #          :add_chunk_num2 => [full_hash0]
    #         }
    # }
    #
    # BODY        = ([MAC LF] HASHENTRY+) | (REKEY LF) EOF
    # HASHENTRY   = LISTNAME ":" ADDCHUNK ":" HASHDATALEN LF HASHDATA
    # ADDCHUNK    = DIGIT+                          # Add chunk number
    # HASHDATALEN = DIGIT+                          # Length of HASHDATA
    # HASHDATA    = <HASHDATALEN number of unsigned bytes>  # Full length hashes in binary
    # MAC         = (LOALPHA | DIGIT)+
    # 
    # Ignore rekey response for now
    #
    def parse_full_hash_entries str
      full_list = {}
      scanner = StringScanner.new(str)
      count = 0; scanner.pos = 0

      while !(head = scanner.scan_until(FULL_HASH_HEAD)).nil?
        m = FULL_HASH_HEAD.match head
        return full_list if m[:rekey]
        
        count += 1
        list_name, chunk_num, chunk_len = m[:list].to_s.to_sym, m[:chunk_num].to_i, m[:chunk_len].to_i
        pointer = 0; chunk_data = []
        
        my_list = (full_list[list_name] ||= {})
        my_list[chunk_num] ||= []
        
        while pointer < chunk_len
          chunk_data << scanner.get_byte
          pointer += 1
        end

        parse_full_hash_data chunk_data, my_list[chunk_num]
      end
      
      full_list
    end
    
    def parse_full_hash_data byte_arr, full_hash_arr
      byte_arr.each_slice(FULL_HASH_SIZE) do |slice|
        full_hash_arr << slice.join('').unpack("H#{FULL_HASH_SIZE*2}").first
      end
    end

  end
end
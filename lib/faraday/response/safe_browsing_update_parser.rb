require 'faraday'

module Faraday
  class Response
    
    class SafeBrowsingUpdateParser < ::Faraday::Response::Middleware

      REKEY ||= /(e):(pleaserekey)/
      NEXT  ||= /(n):(\d+)/
      RESET ||= /(r):(pleasereset)/
      LIST  ||= /(i):(.+)/
      
      MIX_LINE ||= /(i|u|ad|sd):(.+)/
      CHUNK_LIST ||= /(\d+-\d+|\d+)/
      
      # define_parser do |body|
      def parse body
        @update_obj = Google::SafeBrowsingUpdate.new
        parse_data_response(body)
        @update_obj
      end
      
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
      def parse_data_response body
        lines = body.split(%Q(\n))
        text = lines.shift
        if REKEY =~ text
          @update_obj.rekey = true
          text = lines.shift
        end
        # the line is NEXT line
        parse_next text
        return if @update_obj.rekey
        
        text = lines.shift
        if RESET =~ text
          @update_obj.reset = true
          return
        end
        # the line is the LIST line
        parse_list text
        while !(text = lines.shift).nil?
          parse_mix_line text
        end
      end
      
      
      def parse_next line
        m = NEXT.match(line.to_s)
        if m.nil?
          raise Google::Error::ParserError
        else
          @update_obj.next = m[2].to_i
        end
      end
      
      def parse_list line
        m = LIST.match(line.to_s)
        if m.nil?
          raise Google::Error::ParserError
        else
          @update_obj.set_current_list(m[2])
        end
      end
    
      def parse_mix_line line
        m = MIX_LINE.match(line.to_s)
        raise Google::Error::ParserError if m.nil?
        my_list = @update_obj.get_current_list
        
        case m[1]
        when 'i'
          @update_obj.set_current_list m[2]
        when 'u'
          my_list[:u] << m[2].strip
        when 'sd'
          parse_chunk_list m[2], my_list[:sd]
        when 'ad'
          parse_chunk_list m[2], my_list[:ad]
        else
          raise Google::Error::ParserError
        end
      end
      
      def parse_chunk_list chunk_list, cached_chunks
        chunks = chunk_list.split(',')
        while !(chunk = chunks.shift).nil?
          m = CHUNK_LIST.match(chunk)
          raise Google::Error::ParserError if m.nil?
          if m[0].include?('-')
            low, upper = m[0].split('-').map {|x| x.to_i}
            cached_chunks << (low..upper)  # Range
          else
            cached_chunks << m[0].to_i
          end
        end
      end

    end
  
  end
end
    
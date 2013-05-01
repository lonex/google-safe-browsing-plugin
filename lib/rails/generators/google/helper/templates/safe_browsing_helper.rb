module Google
  module SafeBrowsingHelper
    extend self
  
    def save_full_hash_requests prefixes, state, requested_at = Time.now
      prefixes.each do |pre|
        obj = SafeBrowsingFullHashRequest.where(prefix: pre).first
        if obj.nil?
          obj = SafeBrowsingFullHashRequest.create(prefix: pre, requested_at: requested_at, state: state)
        else
          obj.update_attributes(requested_at: requested_at, state: state)
        end
      end
    end
    
  
    #
    # hash_prefix_arr: ['5b3583c0', 'b3e357a6']
    #
    def get_full_hash_list hash_prefix_arr
      ret_full_hashes = []
      api =  SafeBrowsingClient.new

      return ret_full_hashes if hash_prefix_arr.empty?
      
      begin
        full_hash_objs = api.full_hash(hash_prefix_arr) || {}
        save_full_hash_requests(hash_prefix_arr, SafeBrowsingFullHashRequest::COMPLETED)
      rescue Google::Error::NoContent => e
        Rails.logger.warn "NoContent Error for hash prefixes [#{hash_prefix_arr.join(', ')}]"
        save_full_hash_requests(hash_prefix_arr, SafeBrowsingFullHashRequest::COMPLETED)
        return ret_full_hashes
      rescue Exception => e
        Rails.logger.error "Error backtrace #{e.backtrace.join(%Q(\n))}"
        Rails.logger.warn "Error (#{e.inspect}) for hash prefixes [#{hash_prefix_arr.join(', ')}], continue..."
        save_full_hash_requests(hash_prefix_arr, e.message)
        return ret_full_hashes
      end
        
      full_hash_objs.keys.each do |list|
        full_hash_objs[list].keys.each do |add_chunk_num|
          full_hash_objs[list][add_chunk_num].each do |full_hash|
            unless (list_obj = SafeBrowsingList.list_by_name(list)).nil?
              Rails.logger.info "Updating full hash data with #{list}:#{add_chunk_num}:#{full_hash}"
              local = SafeBrowsingFullHash.where(value: full_hash).first

              if local
                local.touch
              else
                local = SafeBrowsingFullHash.create(value: full_hash, add_chunk_num: add_chunk_num, 
                                        google_safe_browsing_list_id: list_obj.id)
              end
              
              ret_full_hashes << full_hash
            end
          end
        end
      end
      
      ret_full_hashes
    end
    
    def can_request_full_hash? hash_prefix
      now = Time.now
      request = Google::SafeBrowsingFullHashRequest.where(prefix: hash_prefix).first
      if request.nil?
        true
      else
        if request.state == SafeBrowsingFullHashRequest::COMPLETED
          if request.requested_at < now - Google::CONFIG['full_length_hash_expires']
            true
          else
            Rails.logger.warn "Full hash [#{hash_prefix}] requested successfully recently, skip this time."
            false
          end
        else
          attempts = request.attempts.nil?? 1 : request.attempts
          max_delay = Google::CONFIG['full_length_hash_backoff_delay_max']
          delay = attempts * Google::CONFIG['full_length_hash_backoff_delay']
          delay = max_delay if delay > max_delay
          if request.requested_at > now - delay
            Rails.logger.warn "Full hash [#{hash_prefix}] request in backoff mode. Wait time is #{delay} seconds"
            false
          else
            true
          end
        end
      end
    end
    
    def lookup_url url
      canon_url = Google::UrlCanonicalizer.apply(url)
      hosts_set, urls_set = Google::UrlScramble.gen(canon_url)
      full_hits = []
      
      unless hosts_set.empty?
        host_shas = hosts_set.map {|x| ShaUtil.sha256_hex(x, 8)}
        host_hits = find_host_key_hits(host_shas).map(&:host_key)
        
        if host_hits.empty?
          Rails.logger.info "No host key prefix found. Return."
          return hits_to_category(url, full_hits)
        else
          url_shas = urls_set.map {|x| ShaUtil.sha256_hex(x, 8)}
          prefix_hits = find_prefix_key_hits(host_shas, url_shas).map(&:prefix)
          
          candidate_prefixes = (host_hits + prefix_hits).uniq
          full_hash_expressions = urls_set.map {|x| ShaUtil.sha256_hex(x)}.select {|x| candidate_prefixes.include?(x.first(8))}
          full_hits = full_hash_cache_hits(full_hash_expressions)

          if full_hits.empty?
            warm_prefixes = candidate_prefixes.select {|x| !can_request_full_hash?(x)}
            candidate_prefixes -= warm_prefixes
            unless candidate_prefixes.empty?
              Rails.logger.info "Asking Google for full length hash #{candidate_prefixes}"
              get_full_hash_list(candidate_prefixes) 
              full_hits = full_hash_cache_hits(full_hash_expressions)
            end
          end
        end
      end

      if full_hits.empty?
        Rails.logger.info "Return no hits..."
      else
        Rails.logger.info "Return hits #{full_hits.inspect}..."
      end

      hits_to_category(url, full_hits)
    end
    
    def hits_to_category url, full_hits
      (ret = {}).tap do
        ret[url] ||= []
        full_hits.each do |hit|
          ret[url] << hit.list.name
        end
      end
    end
    
    def find_host_key_hits prefixes
      ret = []
      SafeBrowsingShavar.add_host_keys(prefixes).each do |add|
        if SafeBrowsingShavar.find_subs_for_add(add.chunk_num, add.host_key, add.prefix).empty?
          ret << add
        end
      end
      ret
    end
    
    def find_prefix_key_hits host_keys, prefixes
      ret = []
      SafeBrowsingShavar.add_host_prefixes(host_keys, prefixes).each do |add|
        if SafeBrowsingShavar.find_subs_for_add(add.chunk_num, add.host_key, add.prefix).empty?
          ret << add
        end
      end
      ret
    end
    
    def full_hash_cache_hits full_hashes
      SafeBrowsingFullHash.includes(:list).where(value: full_hashes)
                          .where('updated_at > ?', Time.now - Google::CONFIG['full_length_hash_expires'])
    end
        
    
  end
end
module Google
  module SafeBrowsingUpdateHelper
    
    def update_local_shavar_info update_obj
      gsb = safe_browsing_service
      update_next_update_time(gsb, update_obj.next) if update_obj.next
      if update_obj.reset
        if Rails.configuration.respond_to?(:google_safe_browsing_upon_reset)
           Rails.configuration.google_safe_browsing_upon_reset.call
        else
          Rails.logger.warn "I got a reset from Google... Don't know what to do."
        end
      end
        
      if update_obj.has_lists?
        update_obj.lists.keys.each do |name|
          if SafeBrowsingList.valid_list?(name)
            list = SafeBrowsingList.find_by_name(name.to_s)
            update_add_sub_chunks list, update_obj.get_ad_chunk_ids(name), SafeBrowsingShavar::CHUNK_TYPE_ADD
            update_add_sub_chunks list, update_obj.get_sd_chunk_ids(name), SafeBrowsingShavar::CHUNK_TYPE_SUB
          else
            Rails.logger.info "Got invalid list name [#{name}]"
          end
        end
      end
    end
  
    def save_redirect_urls urls, list_obj
      urls.each do |url|
        obj = SafeBrowsingRedirectUrl.for_url_and_list_id(url, list_obj.id).first
        if obj.nil?
          obj = SafeBrowsingRedirectUrl.create(url: url, google_safe_browsing_list_id: list_obj.id)
        end
      end
    end
  
    def update_redirect_urls url, list_obj, attributes
      obj = SafeBrowsingRedirectUrl.for_url_and_list_id(url, list_obj.id).first
      obj.update_attributes(attributes)
    end
    
    def update_add_sub_chunks list_obj, del_chunk_ids, chunk_type
      
      del_chunk_ids.each do |chunk_id|
        if chunk_id.is_a?(Range)
          chunk_id.each do |id|
            SafeBrowsingShavar.where(google_safe_browsing_list_id: list_obj.id, chunk_num: id, chunk_type: chunk_type).destroy_all
          end
        else
          SafeBrowsingShavar.where(google_safe_browsing_list_id: list_obj.id, chunk_num: chunk_id, chunk_type: chunk_type).destroy_all
        end
      end
    end

    def update_shavar_chunk adds, subs, shavar_list
      update_add_shavar_chunk adds, shavar_list
      update_sub_shavar_chunk subs, shavar_list
    end
  
    def update_add_shavar_chunk adds, shavar_list
      adds.each do |add|
        
        chunk_num = add[:chunk_num]
        add[:chunk_data].each do |host_key, prefixes|
          if prefixes.empty?
            shavar = SafeBrowsingShavar.where(
                       google_safe_browsing_list_id: shavar_list.id, 
                       chunk_type: SafeBrowsingShavar::CHUNK_TYPE_ADD, 
                       chunk_num: chunk_num, host_key: host_key, prefix: nil).first_or_create
          else
            prefixes.each do |prefix|
              shavar = SafeBrowsingShavar.where(
                         google_safe_browsing_list_id: shavar_list.id, 
                         chunk_type: SafeBrowsingShavar::CHUNK_TYPE_ADD, 
                         chunk_num: chunk_num, host_key: host_key, prefix: prefix).first_or_create
            end
          end
        end
      end

    end
    
    def update_sub_shavar_chunk subs, shavar_list
      subs.each do |sub|
        chunk_num = sub[:chunk_num]
        
        sub[:chunk_data].each do |host_key, chunk_num_hash_prefix|
          chunk_num_hash_prefix.each do |add_chunk_num, prefixes|
            if prefixes.empty?
              shavar = SafeBrowsingShavar.where(
                         google_safe_browsing_list_id: shavar_list.id, 
                         chunk_type: SafeBrowsingShavar::CHUNK_TYPE_SUB, 
                         chunk_num: chunk_num, host_key: host_key, 
                         add_chunk_num: add_chunk_num, prefix: nil).first_or_create
            else
              prefixes.each do |prefix|
                shavar = SafeBrowsingShavar.where(
                           google_safe_browsing_list_id: shavar_list.id, 
                           chunk_type: SafeBrowsingShavar::CHUNK_TYPE_SUB, 
                           chunk_num: chunk_num, host_key: host_key, 
                           add_chunk_num: add_chunk_num, prefix: prefix).first_or_create
              end
            end
          end # chunk_num_hash_prefix.each
        end # subs[:chunk_data].each
      end # subs.each

    end
    
    #
    # chunk_id_arr: [113121, 113122, 113123, 113132], in increasing order
    # return: "113121-113123,113132"
    #
    def gen_chunk_nums_string chunk_id_arr
      ranges_and_integers = []
      first = last = chunk_id_arr.shift
      return "" if first.nil?
      
      increment = 0
      while !(int = chunk_id_arr.shift).nil?
        increment += 1
        if int == first + increment
          last = int
          next
        else
          if first == last
            ranges_and_integers << first
          else
            ranges_and_integers << (first..last)  
          end

          first = last = int
          increment = 0
        end
      end
      
      if first == last
        ranges_and_integers << first
      else
        ranges_and_integers << (first..last)  
      end
      
      range_and_int_arr_to_string(ranges_and_integers)
    end
    
    
    def safe_browsing_service
      Function.where(name: Function::GoogleSafeBrowsing).first
    end
  
    def update_next_update_time link_function, ts
      link_function.update_attributes(:next_updated_at => Time.now + ts)
    end
  

    protected 
    
    def range_and_int_arr_to_string arr
      ret = []
      arr.each do |member|
        if member.is_a?(Range)
          ret << member.first.to_s + "-" + member.last.to_s
        elsif member.is_a?(Integer)
          ret << member.to_s
        end
      end
      ret.join(",")
    end
  
  end
end
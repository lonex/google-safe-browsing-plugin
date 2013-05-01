require File.expand_path('../../google/safe_browsing_update_helper', __FILE__)

namespace :google do
  namespace :safe_browsing do

    include Google::SafeBrowsingUpdateHelper

    module GoogleTask
      extend self
      
      def gsb_api
        @gsb_api ||= Google::SafeBrowsingClient.new
      end

      def load_remote_shavar_info list
        update_obj = GoogleTask.gsb_api.shavar_data_update list
        update_local_shavar_info update_obj
        update_obj
      end
    
      def load_remote_shavar_chunk url
        chunk_data = GoogleTask.gsb_api.chunk_data(url)
        adds, subs = Google::SafeBrowsingParser.parse_shavar_list(chunk_data)
      end
    
      def load_redirect_urls urls, shavar_list
        Rails.logger.info "Redirect urls: #{urls.join(%Q(\n))}"
        urls.each do |url|
          load_redirect_url url, shavar_list
        end
      end

      def load_history_redirect_urls urls
        Rails.logger.info "Inspecting history failed redirect downloads..."
        Rails.logger.info "Found history failed redirect urls: #{urls.blank?? 'none' : urls.map(&:url).join(%Q(\n))}"
        urls.each do |url|
          load_redirect_url url.url, url.list
        end
      end
    
      def load_redirect_url url, shavar_list
        begin
          Rails.logger.info "Loading data for [#{shavar_list.name}] from redirect url #{url}..."
          adds, subs = load_remote_shavar_chunk(url)
          update_shavar_chunk adds, subs, shavar_list
          update_redirect_urls(url, shavar_list,
                    {download_state: Google::SafeBrowsingRedirectUrl::COMPLETED, last_download_at: Time.now})
        
          Rails.logger.info "Finish loading data from #{url}\n"
        rescue Google::Error::NoContent => e
          Rails.logger.info "NoContent Error for redirect url [#{url}], continue..."
          update_redirect_urls url, shavar_list, {download_state: e.message, last_download_at: Time.now}
        rescue Exception => e
          Rails.logger.info "Error (#{e.inspect}) for redirect url [#{url}], abort..."
          update_redirect_urls url, shavar_list, {download_state: e.message, last_download_at: Time.now}
          raise
        end
      end

      def history_redirect_downloads
        Google::SafeBrowsingRedirectUrl.where("download_state is NULL or download_state != ?", Google::SafeBrowsingRedirectUrl::COMPLETED)
                                       .order("google_safe_browsing_redirect_urls.order").all
      end
      
    end
    
    task :set_logger => :environment do
      Rails.logger = Logger.new(Rails.root.join('log', "google_safe_browsing_#{Rails.env}.log"), 7, 10240000)
    end
    
    desc "Update GoogleSafeBrowsing data"
    task :load_remote => :set_logger do
      Rails.logger = Logger.new(Rails.root.join('log', "google_safe_browsing_#{Rails.env}.log"), 7, 10240000)
      
      Rails.logger.info "=== start load_remote at #{Time.now} ==="
      
      GoogleTask.load_history_redirect_urls(GoogleTask.history_redirect_downloads)
      
      next_updated_at = safe_browsing_service.next_updated_at
      if !next_updated_at.nil? && next_updated_at > Time.now
        abort "Google suggests next update until #{next_updated_at}, but now is #{Time.now}"
      end
      
      [Google::SafeBrowsingList::MalwareList, Google::SafeBrowsingList::PhishList].each do |list_name|
        shavar_list = Google::SafeBrowsingList.find_by_name(list_name.to_s)
      
        update_obj = GoogleTask.load_remote_shavar_info list_name

        if (redirect_urls = update_obj.get_redirect_urls(list_name)).empty?
          Rails.logger.info "No redirect urls detected for #{list_name}"
        else
          (new_redirects = []).tap do
            redirect_urls.each do |url|
              local_obj = Google::SafeBrowsingRedirectUrl.for_url_and_list_id(url, shavar_list.id).first
              unless local_obj.nil?
                Rails.logger.info "Skip the url as it's been processed before #{url}"
              else
                new_redirects << url
              end
            end
          end
          
          save_redirect_urls(new_redirects, shavar_list)
          GoogleTask.load_redirect_urls(redirect_urls, shavar_list)
        end

        Rails.logger.info "=== end of #{list_name} ==="
      end
      
    end

    desc "Seed Google Safe Browsing data"
    task :db_seed => :set_logger do
      Google::Function.where(name: Google::Function::GoogleSafeBrowsing).first_or_create
      
      [Google::SafeBrowsingList::MalwareList, Google::SafeBrowsingList::PhishList].each do |list|
        Google::SafeBrowsingList.where(name: list).first_or_create
      end
    end

  end
end
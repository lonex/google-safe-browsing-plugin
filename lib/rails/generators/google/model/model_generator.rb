require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module Google
  module Generators
    class ModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      source_root File.expand_path('../templates', __FILE__)
  
      def self.next_migration_number path
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def creaet_migrations
        
        %w(create_google_functions.rb
           create_google_safe_browsing_full_hash_requests.rb 
           create_google_safe_browsing_list.rb
           create_google_safe_browsing_shavar.rb
           create_google_safe_browsing_full_hashes.rb
           create_google_safe_browsing_redirect_urls.rb).each do |f|
        
          migration_template "#{f}", "db/migrate/#{f}"
        end

      end

      def create_models
        %w(google.rb
           google/function.rb
           google/error.rb 
           google/safe_browsing_full_hash.rb
           google/safe_browsing_full_hash_request.rb
           google/safe_browsing_list.rb
           google/safe_browsing_redirect_url.rb
           google/safe_browsing_shavar.rb
           google/safe_browsing_update.rb
        ).each do |f|
          template "#{f}", "app/models/#{f}"
        end
      end

    end
  end
end

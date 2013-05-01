require 'active_support/all'

module Google
  def self.table_name_prefix
    'google_'
  end
  
  if defined?(Rails)
    config_file = File.expand_path('./config/google_safe_browsing.yml', Rails.root)
    CONFIG ||= YAML.load_file(config_file)[Rails.env] if File.exists?(config_file)
  end

  autoload :SafeBrowsingClient, 'google/safe_browsing_client'
  autoload :SafeBrowsingParser, 'google/safe_browsing_parser'
  autoload :SafeBrowsingUpdateHelper, 'google/safe_browsing_update_helper'  
  autoload :ShaUtil, 'google/sha_util'
  autoload :UrlCanonicalizer, 'google/url_canonicalizer'
  autoload :UrlScramble, 'google/url_scramble'
end

module Faraday
  class Response
    autoload :SafeBrowsingUpdateParser, 'faraday/response/safe_browsing_update_parser'
  end
end

if defined?(Rake)
  require 'safe_browsing_task'
end
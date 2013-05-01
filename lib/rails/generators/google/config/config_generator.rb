# encoding: utf-8

module Google
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc 'Creates a Google Safe Browsing plugin configuration file config/google_safe_browsing.yml'

      source_root File.expand_path('../templates', __FILE__)

      def copy_config_file
        copy_file 'google_safe_browsing.yml', "config/google_safe_browsing.yml"
      end

    end
  end
end

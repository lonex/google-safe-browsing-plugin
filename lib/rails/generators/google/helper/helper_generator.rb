# encoding: utf-8

module Google
  module Generators
    class HelperGenerator < Rails::Generators::Base
      desc 'Creates a Google Safe Browsing plugin helper file app/helpers/google/safe_browsing_helper.rb'

      source_root File.expand_path('../templates', __FILE__)

      def copy_helper_file
        copy_file 'safe_browsing_helper.rb', "app/helpers/google/safe_browsing_helper.rb"
      end

    end
  end
end

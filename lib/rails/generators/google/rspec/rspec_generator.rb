# encoding: utf-8

module Google
  module Generators
    class RspecGenerator < Rails::Generators::Base
      desc 'Creates a Google Safe Browsing plugin Rspec test files under rspect/google'

      source_root File.expand_path('../templates', __FILE__)

      def copy_spec_files
        %w(
          bin_sample_1.data
          bin_sample_2.data
          full_hash_response_0.data
          full_hash_response_1.data
          full_hash_response_2.data
          full_hash_response_3.data
          full_hash_parse_spec.rb
          shavar_encode_data_parse_spec.rb
          shavar_list_info_parse_spec.rb
        ).each do |f|
          copy_file "#{f}", "spec/google/#{f}"
        end
      end

    end
  end
end

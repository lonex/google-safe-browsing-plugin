module Google
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      GENERATORS = %w(google:config google:helper google:model google:rspec)
      def run_all_generators
        if behavior == :invoke
          GENERATORS.each do |g|
            generate g
          end
        elsif behavior == :revoke
          GENERATORS.reverse.each do |g|
            Rails::Generators.invoke g, [], :behavior => :revoke
          end
        end
      end
      
    end
  end
end
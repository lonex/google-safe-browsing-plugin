class SafeBrowsingTask < Rails::Railtie
  rake_tasks do
    Dir[File.join(File.expand_path('../', __FILE__),'tasks/**/*.rake')].each {|f| load f}
  end
end
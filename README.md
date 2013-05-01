## Google Safe Browsing Plugin

A Rails 3 plugin for [Google Safe Browsing API v2](https://developers.google.com/safe-browsing/developers_guide_v2).
It supports Google malware and phishing list.

## Installation

Add the plugin to your Gemfile

    gem 'google_safe_browsing_plugin', '~> 0.1'

After bundle install, run the following to generate the db migration, model classes and other code

	bundle install
    bundle exec rails g google:install

Run the migrations generated by the previous step, and then seed the databse

    bundle exec rake db:migrate
	bundle exec rake google:safe_browsing:db_seed
	
Edit the configration file with Google API key
    
	# Edit config/google_safe_browsing.yml, and replace the real API key in line 2.
	

## Build the hash prefix data locally

The plugin stores the hash prefixes in the relational database. The following rake task needs to be run under a certain schedule to keep the local data in sync with the Google server list. It may require several runs before you have a relatively complete hash prefix set before you can do any meaningful full hash lookup. 

    bundle exec rake google:safe_browsing:load_remote

## Url lookup

After you run the _'load_remote'_ rake task several time, you can start to use the plugin to do url lookup. Start the Rails console, and then try the following

    url = 'financestudyhelp.com'
	r = Google::SafeBrowsingHelper.lookup_url url
	
Since the Google Safe Browsing is so dynamic, the previous query may not necessarily generate hit on Malware, other urls you can try are 'http://gumblar.cn' and 'http://ianfette.org'.

## Uninstall

If you want to uninstall the gem and remove the generated files
   
	rails d google:install

## Features and limitations

* The plugin does not hide the ActiveRecord models and the helper inside the Gem. It instead uses the generator function provided by Rails and Thor to copy the template model/migration/helper code to the Rails application source tree. The generated code is under the namespace _Google_.
* The plugin uses the relational database as the local data store. But it doesn't have to. Redis may be a better choice considering lookup and cache expire. But the local data have to be kept under certain limit. The tables generated from the migration have the _google_ prefix.
* The hash prefix is stored in the database as plain text hash format but not in binary/encoded mode.
* The config parameters, in _config/google\_safe\_browsing.yml_, can be changed to your need. E.g. _full\_length\_hash\_expires_ is for how long the full-length hash will be cached locally.
* The plugin has backoff strategy built in when error happens. So if you notice that the full-length hash request doesn't go to Google, it probably is still in the back-off mode.
* Some RSpec tests are provided in the spec folder.
* The _google:safe\_browsing:load\_remote_ rake task cannot be run repeatedly within a short time span. It honors the _NEXT_ instruction from Google's response. This value is kept in _google\_functions#next\_updated\_at_. You have to change the value when you want to run it frequently, e.g. during dev and test.
* When Google sends out _'reset'_ instruction to the request, the plugin will _not_ clean up the local data by default. You can change the behavior by adding the following configure in application.rb or the environment file in your Rails app:
<pre><code>
	# This will reset your local data
    config.google_safe_browsing_upon_reset = lambda {
      Google::SafeBrowsingShavar.delete_all
    }
</code></pre>

* _'rekey'_ instruction is not supported.
* The plugin works for Rails 3.2. But it should be relatively trivial to make it work with other Rails version because the Rails 3.2 feature that the plugin uses is mostly related to ActiveRecord, e.g. _first\_or\_create_. The encoding/decoding of the Google Safe Browsing data is independent of Rails.


## Reference

* [Safe Browsing API v2](https://developers.google.com/safe-browsing/developers_guide_v2)
* [google-safe-browsing](http://code.google.com/p/google-safe-browsing/wiki/Protocolv2Spec) project on Google code.



Copyright (c) 2013 stonelonely and contributors, released under the MIT license.
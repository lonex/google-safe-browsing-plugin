## Google Safe Browsing Plugin

A Rails 3 plugin for [Google Safe Browsing API v2](https://developers.google.com/safe-browsing/developers_guide_v2).
It supports Google malware and phishing list.

## Installation

Add the plugin to your Gemfile

    gem 'google_safe_browsing_plugin', '~> 0.1'

After bundle install, run the following to generate the db migration, model classes and other code

	bundle install
    bundle exec rails g google:install

Run the migrations generated from the previous step, and then seed the databse

    bundle exec rake db:migrate
	bundle exec rake google:safe_browsing:db_seed
	
Edit the configration file with your Google API key
    
	# Edit config/google_safe_browsing.yml, and replace the real API key in line 2.
	

## Build the hash prefix data locally

The plugin stores the hash prefixes in the relational database. The following rake task needs to be run under a _cron schedule_ to keep the local data in sync with the Google server lists. It may require several runs initially before you have a relatively complete hash prefix set before you can do any meaningful full hash lookup. The first run may take a while because it needs to download quite a bit of data and store them in the local database. The initial run of the rake task could generate quarter a million shavar records in the database.

    bundle exec rake google:safe_browsing:load_remote

## Url lookup

After you run the _'load_remote'_ rake task several times, your local cache of the hash prefixes will be ready. Now you can start to do url lookup. Start the Rails console, and then try the following

    url = 'financestudyhelp.com'
	r = Google::SafeBrowsingHelper.lookup_url url
	
Since the Google Safe Browsing data get updated frequently, the previous query may not necessarily generate hit on Malware, other urls you can try are 'http://gumblar.cn' and 'http://ianfette.org'.

Upon a match on full-length hash lookup, the _lookup\_url_ call will return a hash object that contains the match. E.g. 

    {"financestudyhelp.com"=>["goog-malware-shavar"]}

The key of the hash is the url that's been queried. The array is the match themselves. If the url is both a malware and 
a phishing link, the value will be 
    
	["goog-malware-shavar","googpub-phish-shavar"]
	
If the url is neither a malware nor phishing link, the lookup result will be an empty array [].


## Uninstall

If you want to uninstall the gem and remove the generated files
   
	rails d google:install

## Features and limitations

* The plugin does not hide the ActiveRecord models and the helper inside the Gem. It instead uses the generator function provided by Rails and Thor to copy the template model/migration/helper code to the Rails application source tree. The generated code is under the _Google_ namespace.
* The plugin uses the relational database as the data store. But it doesn't have to. Redis may be a better choice considering lookup speed and cache expire. But the local data have to be kept under certain limit. The tables generated from the migration have _google_ as the prefix.
* The hash prefix is stored in the database as plain text but not in binary/encoded format.
* The config parameters, in _config/google\_safe\_browsing.yml_, can be changed to your need. E.g. _full\_length\_hash\_expires_ is for how long the full-length hash will be cached locally.
* The plugin has backoff strategy built in when error happens. So if you notice that the full-length hash request doesn't go to Google, it probably is still in the backoff mode that prevents the request being sent to Google.
* Some RSpec tests are provided in the spec folder.
* The _google:safe\_browsing:load\_remote_ rake task cannot be run repeatedly within a short time span. It honors the _NEXT_ instruction from Google's response. This value is kept in _google\_functions#next\_updated\_at_. You have to change the value if you want to run it immediately after the previous run.
* When Google sends out _'reset'_ instruction to the request, the plugin will _not_ clean up the local data by default. You can change the behavior to reset the data by adding the following configuration in application.rb or the environment file in your Rails app:
<pre><code>
	# This will reset your local data
    config.google_safe_browsing_upon_reset = lambda {
      Google::SafeBrowsingShavar.delete_all
    }
</code></pre>

* _'rekey'_ instruction is not supported.
* The plugin works for Rails 3.2. But it should be relatively trivial to make it work with other Rails version. The reason for using Rails is mostly because of the value ActiveRecord provides for the data mapping and store. The download, parsing and encoding/decoding of the Google Safe Browsing data do not have to use Rails.


## Reference

* [Safe Browsing API v2](https://developers.google.com/safe-browsing/developers_guide_v2)
* [google-safe-browsing](http://code.google.com/p/google-safe-browsing/wiki/Protocolv2Spec) project on Google code.



Copyright (c) 2013 stonelonely and contributors, released under the MIT license.
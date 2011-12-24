# ginjo-rfm

Rfm is a Ruby/Filemaker adapter - a ruby gem that allows scripts and applications to exchange commands and data with Filemaker Pro using Filemaker's XML interface. Ginjo-rfm picks up from the lardawge-rfm gem and continues to refine code and fix bugs. Version 2.0 adds some major enhancements, while remaining compatible with ginjo-rfm 1.4.x and lardawge-rfm 1.4.x.


## Documentation & Links

* Ginjo-rfm rubygem		<https://rubygems.org/gems/ginjo-rfm>
* Original homepage		<http://sixfriedrice.com/wp/products/rfm/>
* Rdoc location				<http://rubydoc.info/github/ginjo/rfm/frames>
* Discussion					<http://groups.google.com/group/rfmcommunity>
* Ginjo at github			<https://github.com/ginjo/rfm>
* Lardawge at github	<https://github.com/lardawge/rfm>


## New in version 2.0

### Data source modeling with ActiveModel and graceful degradation without ActiveModel.
	
If you can load ActiveModel in your project, you can have model callbacks, validations, and other ActiveModel features.
If you can't load ActiveModel (because you're using something incompatible, like Rails 2),
you can still use Rfm models... minus callbacks & validations. Rfm models give you basic
data modeling with easy configuration and CRUD features.

	  class User < Rfm::Base
	    config      :layout => 'user_layout'
	  end
	
	  @user = User.find 12345
	  @user.update_attributes(:name => 'bill', :login => 'admin')
	  @user.save!

With ActiveModel loaded, you get callbacks, validations, and many other ActiveModel features.

	  class User < Rfm::Base
	    config      :layout=>'user_layout'
	    before_save :encrypt_password
	    validate    :valid_email_address
	  end
	
	  @user = User.new :username => 'bill', :password => 'pass'
	  @user.email = 'my@email.com'
	  @user.save!
	
If you prefer, you can create models on-the-fly from any layout.

	  my_layout.modelize
	  => MyLayoutName   (a class constant, represented by your layout's name)
	 
Or create models for an entire database, all at once.

	  Rfm.modelize :my_db_name_or_config
	  => [MyLayout, AnotherLayout, ThirdLayout, AndSoOn, ...]
	
  
### Choice of XML parsers

Ginjo-rfm 2.0 uses ActiveSupport's XmlMini parsing interface, which has built-in support for
LibXML, Nokogiri, and REXML. Additionally, ginjo-rfm includes a module for Hpricot parsing.
You can specifiy which parser to use or load them all and let Rfm decide.

	  Rfm.config :parser => :libxml

If you're not able to install one of the faster parsers, ginjo-rfm will fall back to
ruby's built-in REXML. Want to roll your own XML adapter? Just pass it to Rfm as a module.

	  Rfm.config :parser => MyHomeGrownAdapter

Choose your preferred parser globaly, as in the above example, or set a different parser for each model.
		
	  class Order < Rfm::Base
	    config :parser => :hpricot
	  end
	
Not only do you have 4 XML backend parsers to choose from, but you also have the option of choosing from different parsing shemes - the DOM parsing scheme, or the streaming (SAX or SAX-like) scheme. This gives you six different available parsing schemes.

* LibXML DOM
* LibXML SAX
* Nokogiri DOM
* Nokogiri SAX
* Hpricot DOM
* REXML DOM

### Configuration API

The ginjo-rfm configuration module is a heirarchical system that allows you to configure settings at a global level
and then recall just the settings you need, where you need them. Configuration settings can be simple
values, or they can be named groups of values.

For simple applications, put all of your configuration in a top-level hash, RFM_CONFIG,
and let Rfm do the rest. For more complicated setups, use configuration subgroups,
and/or set configuration on-the-fly when you create Server, Database, Layout, or Base objects.

Use RFM_CONFIG

	   RFM_CONFIG = {
	     :host          => 'main_host',
	     :database      => 'main_database',
	     :account_name  => 'myname',
	     :password      => 'somepass',
	     :second_server => {
	       :host        => 'second_host',
	       :database    => 'second_database'
	     }

Or set global configuration with the 'config' method

	  Rfm.config :host => 'main_host',
	    :database      => 'main_database',
	    :account_name  => 'myname',
	    :password      => 'somepass',
	    :second_server => {
	      :host        => 'second_host',
	      :database    => 'second_database'
	    }
	
Set configuration of RFM::Base

	   Rfm::Base.config :ssl => true

Set a model's configuration
	
	   class MyClass < Rfm::Base
	     config :second_server, :layout => 'mylayout'
	   end
	
View	model-specific configuration
   
	   MyClass.config
   
	   =>  {:host => 'second_host', :database => 'second_database'}

View the merged configurations of all relevent objects.

	   MyClass.get_config
	   => {:host => 'second_host', :database => 'second_database', :account_name => 'myname', :password => 'somepass', :ssl => true}


Calling this method will show you what compilation of config settings are seen at any given point in Rfm and/or in your application. The current heirarchy of configurable objects in Rfm, starting at the top:

* RFM_CONFIG   # a user-defined hash
* Rfm::Config  # top-level config module
* Rfm::Factory # where server, database, and layout objects are managed
* Rfm::Base    # master modeling class
* MyModel      # custom modeling class




### Complex Queries

Create queries with mixed boolean logic, mimicing Filemaker's multiple-request find.

	   layout.query :fieldOne => ['val1','val2','val3'], :fieldTwo =>'someValue'
   
This will create 3 "find requests" (in a single call to FM Server), one for each value in the fieldOne array, AND'd with the fieldTwo value.


### Full Metadata Support
	
* Server databases
* Database layouts
* Database scripts
* Layout fields
* Layout portals
* Resultset meta
* Field meta
* Portal meta

From ginjo-rfm 1.4.x, the following enhancements are also included.

* Connection timeout settings

* Value-list alternate display

There are also many enhancements to make it easier than ever to get the objects or data you want. Some examples:

Get a database object using default config

	  Rfm.db 'my_db'

Get a layout object using config grouping :my_group
	
	  Rfm.layout :my_group

Get the total count of all records in the table

	  MyModel.total_count

Get the portal names (table-occurence names) on the current layout

	  MyModel.portal_names

Get the names of fields on the current layout

	  my_record.field_names


## Installation

Ginjo-rfm requires ActiveSupport for several features, including XML parsing. Rfm has been tested and works with ActiveSupport 2.3.5 thru 3.1.3. ActiveModel requires ActiveSupport and is not compatible with ActiveSupport 2.3.x. So while you CAN use ginjo-rfm with Rails 2.3, you will not have ActiveModel features like callbacks and validations. Model creation and Filemaker interaction will continue to work, unaffected by the presence or absence of ActiveModel.

To get the best performance, it is recommended that you use the LibXML or Nokogiri parser. Ginjo-rfm does not require these gems by dependency, so you will have to make sure they are installed on your machine and/or specified in your Gemfile, if you wish to use them. Similarly, ginjo-rfm does not require ActiveModel by dependency, so also make sure that is installed and/or specified in your Gemfile, if you wish to have ActiveModel features.

#### Using Bundler and/or Rails >= 3.0

In the Gemfile:

	   gem 'ginjo-rfm'
   
	   gem 'libxml-ruby' # optional
	   gem 'nokogiri'    # optional
	   gem 'hpricot'     # optional
	   gem 'activemodel' # optional

In your shell:

	   bundle install

In your project, you may or may not have to require 'rfm', depending on Bundler's configuration:

	   require 'rfm'

#### Without Bundler

If you're not using Bundler, Rfm will pick up the XML parsers and ActiveModel as long as they are available in your current rubygems installation.

In your shell:

	   #bash
	   gem install ginjo-rfm
	   gem install nokogiri     # optional
	   gem install libxml-ruby  # optional
	   gem install hpricot      # optional
	   gem install activemodel  # optional

Once the gem is installed, you can use rfm in your ruby scripts by requiring it:

	   require 'rubygems'
	   require 'rfm'



#### Edge - in an upcoming version of ginjo-rfm

Try out unreleased features of ginjo-rfm in the edge branch.

	   #gemfile
	   gem 'ginjo-rfm', :git=>'git://github.com/ginjo/rfm.git', :branch=>'edge'
   
   

## Basic usage

### With models

* Set RFM_CONFIG with your configuration data

* Load Rfm

* Specify some models

* Rfm models have the same methods available to them as Rfm layout objects

### Manually

Create a layout object

	   Rfm::Server.new(RFM_CONFIG)['my_db_name']['my_layout_name']

### Finding and manipulating Filemaker data

...



# Working with "classic" Rfm

All of Rfm's original features and functions are available as they were before. Some functions have been enhanced, and just a very few have been modified from their original spec.


		
## Connecting

IMPORTANT:SSL and Certificate verification are on by default. Please see Server#new in rdocs for explanation and setup.
You connect with the Rfm::Server object. This little buddy will be your window into FileMaker data.

	   require 'rfm'

	   my_server = Rfm::Server.new(
	     :host           => 'myservername',
	     :account_name   => 'user',
	     :password       => 'pw',
	     :ssl            => false
	   )

if your web publishing engine runs on a port other than 80, you can provide the port number as well:

	   my_server = Rfm::Server.new(
	     :host           => 'myservername',
	     :account_name   => 'user',
	     :password       => 'pw',
	     :port           => 8080, 
	     :ssl            => false,
	     :root_cert      => false
	   )

## Databases and Layouts

All access to data in FileMaker's XML interface is done through layouts, and layouts live in databases. The Rfm::Server object has a collection of databases called 'db'. So to get ahold of a database called "My Database", you can do this:

	   my_db = my_server.db["My Database"]

As a convenience, you can do this too:

	   my_db = my_server["My Database"]

Finally, if you want to introspect the server and find out what databases are available, you can do this:

	   all_dbs = my_server.db.all

In any case, you get back Rfm::Database objects. A database object in turn has a property called "layout":

	   my_layout = my_db.layout["My Layout"]

Again, for convenience:

	   my_layout = my_db["My Layout"]

And to get them all:

	   all_layouts = my_db.layout.all

Bringing it all together, you can do this to go straight from a server to a specific layout:

	   my_layout = my_server["My Database"]["My Layout"]

## Working with Layouts

Once you have a layout object, you can start doing some real work. To get every record from the layout:

	   my_layout.all   # be careful with this

To get a random record:

	   my_layout.any

To find every record with "Arizona" in the "State" field:

	   my_layout.find({"State" => "Arizona"})

To add a new record with my personal info:

	   my_layout.create({
	     :first_name   => "Geoff",
	     :last_name    => "Coffey",
	     :email        => "gwcoffey@gmail.com"}
	   )

Notice that in this case I used symbols instead of strings for the hash keys. The API will accept either form, so if your field names don't have whitespace or punctuation, you might prefer the symbol notation.

To edit the record whose recid (filemaker internal record id) is 200:

	   my_layout.edit(200, {:first_name => 'Mamie'})

Note: See the "Record Objects" section below for more on editing records.

To delete the record whose recid is 200:

	   my_layout.delete(200)

All of these methods return an Rfm::Result::ResultSet object (see below), and every one of them takes an optional parameter (the very last one) with additional options. For example, to find just a page full of records, you can do this:

	   my_layout.find({:state => "AZ"}, {:max_records => 10, :skip_records => 100})

For a complete list of the available options, see the "expand_options" method in the Rfm::Server object in the file named rfm_command.rb.

Finally, if filemaker returns an error when executing any of these methods, an error will be raised in your ruby script. There is one exception to this, though. If a find results in no records being found (FileMaker error # 401) I just ignore it and return you a ResultSet with zero records in it. If you prefer an error in this case, add :raise_on_401 => true to the options you pass the Rfm::Server when you create it.


## ResultSet and Record Objects

Any method on the Layout object that returns data will return a ResultSet object. Rfm::Result::ResultSet is a subclass of Array, so first and foremost, you can use it like any other array:

	   my_result = my_layout.any
	   my_result.size  # returns '1'
	   my_result[0]    # returns the first record (an Rfm::Result::Record object)

The ResultSet object also tells you information about the fields and portals in the result. ResultSet#fields and ResultSet#portals are both standard ruby hashes, with strings for keys. The fields hash has Rfm::Result::Field objects for values. The portals hash has another hash for its values. This nested hash is the fields on the portal. This would print out all the field names:

	   my_result.fields.each { |name, field| puts name }

This would print out the tables each portal on the layout is associated with. Below each table name, and indented, it will print the names of all the fields on each portal.

	   my_result.portals.each { |table, fields|
	     puts "table: #{table}"
	     fields.each { |name, field| puts "\t#{name}"}
	   }

But most importantly, the ResultSet contains record objects. Rfm::Result::Record is a subclass of Hash, so it can be used in many standard ways. This code would print the value in the 'first_name' field in the first record of the ResultSet:

	   my_record = my_result[0]
	   puts my_record["first_name"]

As a convenience, if your field names are valid ruby method names (ie, they don't have spaces or odd punctuation in them), you can do this instead:

	   puts my_record.first_name

Since ResultSets are arrays and Records are hashes, you can take advantage of Ruby's wonderful expressiveness. For example, to get a comma-separated list of the full names of all the people in California, you could do this:

	   my_layout.find(:state => 'CA').collect {|rec| "#{rec.first_name} #{rec.last_name}"}.join(", ")

Record objects can also be edited:

	   my_record.first_name = 'Isabel'

Once you have made a series of edits, you can save them back to the database like this:

	   my_record.save

The save operation causes the record to be reloaded from the database, so any changes that have been made outside your script will also be picked up after the save.

If you want to detect concurrent modification, you can do this instead:

	   my_record.save_if_not_modified

This version will refuse to update the database and raise an error if the record was modified after it was loaded but before it was saved.

Record objects also have portals. While the portals in a ResultSet tell you about the tables and fields the portals show, the portals in a Record have the actual data. For example, if an Order record has Line Item records, you could do this:

	   my_order = order_layout.any[0]  # the [0] is important!
	   my_lines = my_order.portals["Line Items"]

At the end of the previous block of code, my_lines is an array of Record objects. In this case, they are the records in the "Line Items" portal for the particular order record. You can then operate on them as you would any other record. 

NOTE: Fields on a portal have the table name and the "::" stripped off of their names if they belong to the table the portal is tied to. In other words, if our "Line Items" portal includes a quantity field and a price field, you would do this:

	   my_lines[0]["Quantity"]
	   my_lines[0]["Price"]

You would NOT do this:

	   my_lines[0]["Line Items::Quantity"]
	   my_lines[0]["Line Items::Quantity"]

My feeling is that the table name is redundant and cumbersome if it is the same as the portal's table. This is also up for debate.

Again, you can string things together with Ruby. This will calculate the total dollar amount of the order:

	   total = 0.0
	   my_order.portals["Line Items"].each {|line| total += line.quantity * line.price}

## Data Types

FileMaker's field types are coerced to Ruby types thusly:

	   Text Field       -> String object  
	   Number Field     -> BigDecimal object  # see below  
	   Date Field       -> Date object  
	   Time Field       -> DateTime object # see below  
	   TimeStamp Field  -> DateTime object  
	   Container Field  -> URI object  

FileMaker's number field is insanely robust. The only data type in ruby that can handle the same magnitude and precision of a FileMaker number is Ruby's BigDecimal. (This is an extension class, so you have to require 'bigdecimal' to use it yourself). Unfortuantely, BigDecimal is not a "normal" ruby numeric class, so it might be really annoying that your tiny filemaker numbers have to go this route. This is a great topic for debate.

Also, Ruby doesn't have a Time type that stores just a normal time (with no date attached). The Time class in ruby is a lot like DateTime, or a Timestamp in FileMaker. When I get a Time field from FileMaker, I turn it into a DateTime object, and set its date to the oldest date Ruby supports. You can still compare these in all the normal ways, so this should be fine, but it will look weird if you, ie, to_s one and see an odd date attached to your time.

Finally, container fields will come back as URI objects. You can:

	- use Net::HTTP to download the contents of the container field using this URI
	- to_s the URI and use it as the src attribute of an HTML image tag
	- etc...

Specifically, the URI refers to the _contents_ of the container field. When accessed, the file, picture, or movie in the field will be downloaded.

## Troubleshooting

There are two cheesy methods to help track down problems. When you create a server object, you can provide two additional optional parameters:

:log_actions
When this is 'true' your script will write every URL it sends to the web publishing engine to standard out. For the rails users, this means the action url will wind up in your WEBrick or Mongrel log. If you can't make sense of what you're getting, you might try copying the URL into your browser to see what is actually coming back from FileMaker.

:log_responses
When this is 'true' your script will dump the actual response it got from FileMaker to standard out (again, in rails, check your logs).

So, for an annoying, but detailed load of output, make a connection like this:

	   my_server => Rfm::Server.new(
	     :host             => 'myservername',
	     :account_name     => 'user',
	     :password         => 'pw',
	     :log_actions      => true,
	     :log_responses    => true
	   )


## Credits

Rfm was primarily designed by Six Fried Rice co-founder Geoff Coffey.

Other lead contributors:

* Mufaddal Khumri helped architect Rfm in the most ruby-like way possible. He also contributed the outstanding error handling code and a comprehensive hierarchy of error classes.
* Atsushi Matsuo was an early Rfm tester, and provided outstanding feedback, critical code fixes, and a lot of web exposure.
* Jesse Antunes helped ensure that Rfm is stable and functional.
* Larry Sprock added ssl support, switched the xml parser to a much faster Nokogiri, added the rspec testing framework, and refined code architecture.

## Copyright

Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumr. See LICENSE for details.

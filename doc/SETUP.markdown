# Setup #

This is a standard Ruby on Rails project with only a few special considerations, so and there are probably quite a few options for deploying it beyond what is described below.

I'll assume you have a Linux server and basic administrator skills (i.e. you know how to set up a vhost in Apache).


## Install Ruby ##

The server is a Ruby on Rails application, so you need Ruby. It's tested only with Ruby 1.8 at the moment, but if unit tests pass with another version then it'll probably work. I recommend uninstalling the ruby that came with your distribution's package manager and using [Ruby EE](http://www.rubyenterpriseedition.com/) instead.


## Install mod_passenger ##

Install [mod_passenger](http://www.modrails.com/). If you got Ruby EE then you already have it. Follow the instructions to set it up. We'll get to the apache configuration in a little bit.


## Get tmc-server and dependencies ##

Create a new user, say "tmc", to run the webapp: `adduser tmc`.

As the `tmc` user, get a copy of tmc-server: `git clone <github-url>`. You may want to make your own fork or use a stable branch since any development will take place in the master branch. I'll assume you checked out the webapp to `/home/tmc/tmc-server`.

As `root`, install the bundler gem: `gem install bundler`.

As `tmc`, go to `/home/tmc/tmc-server` and do `bundle install` to install all necessary gems.


## Run the test suite ##

Initialize the development database: `rake db:setup` and run the test suite: `rake spec`.

If something fails, you'll likely have problems. Let us know if you encounter a failure that's not clearly a problem of your setup.


## Initialize the production database ##

The production database will be an sqlite database in `db/production.sqlite3` by default. Other SQL database systems will probably work as well, but I recommend running the test suite first.

To create the production database, run `RAILS_ENV=production rake db:setup`.


## Set up Apache ##

mod_passenger will see the owner of the webapp and run it as `tmc`, but Apache still requires access to the public/ and tmp/ directories, so make sure they are world-readable (and as usual that `/home/tmc` has the x-bit on).

We need one more module for zip downloads to work, namely [XSendFile](https://tn123.org/mod_xsendfile/). Download and install it as from your distro's repo or manually from the website. Make sure it's activated it in the Apache configs.

It's recommended to install the program in a virtual host of its own. Here's an example configuration.

    <VirtualHost *:80>
            ServerName tmc.example.com
            
            DocumentRoot /home/tmc/tmc-server/public
            <Directory /home/tmc/tmc-server/public>
               AllowOverride all
               Options -MultiViews
            </Directory>

            # All sent files will be under tmp/cache/gitrepos
            XSendFile on
            XSendFilePath /home/tmc/tmc-server/tmp/cache/gitrepos

            ErrorLog /var/log/apache2/error.log
            LogLevel warn
            CustomLog /var/log/apache2/access.log combined
    </VirtualHost>

That should be it. Restart apache and give it a try. By default there is a user "admin" with password "admin". Obviously you should either change its password or delete it :)

Let us know if you have any problems.



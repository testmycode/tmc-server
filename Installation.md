## Setup ##

### Notices before installation ###

We assume you use [RVM](https://rvm.io/). If you don't, then replace `rvmsudo` with `sudo` during the installation process.

:exclamation: RVM 1.17.x may have some [problems with rvmsudo](http://stackoverflow.com/questions/13765520/rvmsudo-command-not-working-properly).

An X server is currently needed for browser tests to pass when using Selenium. `Xvfb` will do, but remember to set your `DISPLAY`.

For testing environment PhantomJS (at least version 1.8.1) is required by Poltergeist gem to run headless browser tests. See [poltergeist](https://github.com/teampoltergeist/poltergeist) for documentation.

If you are using Java 8, the following test will fail `RemoteSandboxForTesting should include tools.jar in the classpath for ant projects`. Please refer tp [issue #232](https://github.com/testmycode/tmc-server/issues/232) for further information.

Below is a quick summary of the setup procedure. It is followed by detailed instructions for Ubuntu.

### Quick summary ###

The following programs should be installed first: `ruby` (and `bundler` gem), `PostgreSQL 9.2+`, `screen`,`git`, `zip`, `unzip`, `convert` (from ImageMagick), `javac`, `java`, `ant`, `mvn`, `gcc`, `make` and `bc`. Additionally, tmc-sandbox requires: `squashfs-tools`, `multistrap` `e2fsprogs`, `e2tools` and `build-essential`.

1. Download submodules with `git submodule update --init --recursive`
2. Install dependencies with `bundle install`
3. Edit `config/site.yml`, based on `config/site.defaults.yml`.
4. Setup PostgreSQL based on `config/database.yml` or configure `config/database.local.yml` according to your current postgres settings.
5. Initialize rails database with `rake db:reset`
6. Go to `ext/tmc-sandbox` and compile with `sudo make`. More information from [tmc-sandbox page](https://github.com/testmycode/tmc-sandbox).
7. Go to `ext/tmc-sandbox/web` and install dependencies with `bundle install`. Compile extensions with `rake ext` and run tests with `rvmsudo rake test`.
8. Compile the other stuff in `ext` by doing `rake compile`
9. Install [tmc-check](https://github.com/testmycode/tmc-check) by running `rvmsudo make rubygems install clean` in `ext/tmc-sandbox/uml/output/tmc-check`.
10. Run the test suite with `rvmsudo rake spec`.

After you get the test suite to pass see [post-install instructions](#post-install-instructions).

### Installation ###

The following is a set of detailed instructions for setting tmc-server up on Ubuntu 14.04.

#### Set Java, Ruby and PhantomJS versions to be installed ####

```
$ JAVA_VERSION=7
$ RUBY_VERSION=2.2.0
```

#### Install dependencies ####

Update your package list with
```
$ sudo apt-get update
```

TMC-server dependencies
```
$ sudo apt-get install git build-essential zip unzip imagemagick maven make phantomjs bc xvfb postgresql postgresql-contrib chrpath libssl-dev libxft-dev \
  libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev
```
Ruby dependencies
```
$ sudo apt-get install git-core curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
```
RVM dependencies
```
$ sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
```
TMC-sandbox dependencies
```
$ sudo apt-get install squashfs-tools multistrap e2fsprogs e2tools
```

#### Java installation ####

To install OpenJDK 7 run
```
$ sudo apt-get install openjdk-7-jdk
```
If you want to install the official Oracle JDK, you need to add a ppa repository. You can install Oracle JDK with the following commands
```
$ sudo add-apt-repository ppa:webupd8team/java
$ sudo apt-get update
$ sudo apt-get install oracle-java$JAVA_VERSION-installer
```

#### Installing PhantomJS ####
:exclamation: Not necessary if your package manager installed PhantomJS version `1.8.1` or later.

Remove the version package manager installed. Download PhantomJS from their [website](http://phantomjs.org/) by running the commands below.
```
sudo apt-get remove phantomjs
$ PHANTOM_JS="phantomjs-1.9.8-linux-x86_64"
$ wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2
```
After the download finishes, extract the files and create symlinks
```
$ tar -xvjf $PHANTOM_JS.tar.bz2
$ sudo mv $PHANTOM_JS /usr/local/share
$ sudo ln -s /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin
$ rm $PHANTOM_JS.tar.bz2
```
Check that PhantomJS is installed correctly
```
$ phantomjs --version
```

### Install ruby via RVM ###
#### Install RVM as multi-user install ####

```
$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
$ \curl -L https://get.rvm.io | sudo bash -s stable
```

After installation finishes add new user and set up groups

```
$ sudo adduser tmc
$ sudo addgroup rvm
$ sudo usermod -a -G rvm tmc
$ sudo /usr/local/rvm/bin/rvm install $RUBY_VERSION
$ sudo /usr/local/rvm/bin/rvm use $RUBY_VERSION --default
```

Set up ruby path

```
$ echo 'export PATH=$PATH:/usr/local/rvm/rubies/ruby-$RUBY_VERSION/bin' | sudo tee -a /etc/profile.d/ruby.sh
$ source /etc/profile.d/ruby.sh
```

#### Switch to tmc user ####

```
$ sudo -i -u tmc
```

#### Import public key for rvm installation ####

```
$ command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
$ rvm get stable
```

#### Set up user environment variables ####

```
$ echo "export GEM_HOME=$(ruby -e 'print Gem.user_dir')" >> ~/.bashrc
$ echo "export PATH=$PATH:$GEM_HOME/bin" >> ~/.bashrc
$ export GEM_HOME=$(ruby -e 'print Gem.user_dir')
$ export PATH=$PATH:$GEM_HOME/bin
```

### PostgreSQL ###
#### Create postgres user ####

Run following command and when prompted give **tmc** as a password, if you want to use another username or stronger password change them into **config/database.local.yml**.

```
$ createuser tmc -s -P
```

If you cannot run the above command, you can also create the user manually

```
$ sudo -u postgres psql -c "CREATE USER tmc WITH SUPERUSER CREATEUSER CREATEDB PASSWORD 'tmc';"
```
:exclamation: Superuser access is useful for dev environment, but discouraged for production.

#### Set PostgreSQL to authenticate with md5 instead of local ####

Locate the **pg_hba.conf** file with `locate pg_hba.conf`. The file should be located */etc/postgresql/<version number>/main/pg_hba.conf*. Open the file with your preferred text-editor. You need root privileges to edit the file. Around line 90 change
```
# "local" is for Unix domain socket connections only
local   all             all                                     peer
```
to
```
# "local" is for Unix domain socket connections only
local   all             all                                     md5
```

### TMC-server installation ###
#### Clone the TMC repository ####

```
$ cd tmc-server
$ git clone https://github.com/testmycode/tmc-server.git
```
:exclamation: If you are not using a github account, replace the repository submodule URLs with a HTTPS URL in .git/config e.g. `https://github.com/testmycode/tmc-checkstyle-runner.git`
```
$ git submodule update --init --recursive
$ gem install bundler && bundle install
```
You can view the site settings from the file `config/site.defaults.yml`. If you want to change the settings for the site, create a new file `config/site.yml` and define the changes there (notice: you do not need to copy the entire file. Settings not in `site.yml` will be looked up from `site.defaults.yml`).

Initialize the database with `rake db:reset`
#### Build sandbox ####

```
$ cd ext/tmc-sandbox
$ sudo make
```

#### Install tmc-sandbox web dependencies ####

```
$ cd web
$ bundle install
$ rake ext
$ rvmsudo rake test
```

#### Compile rest of the externals ####

```
$ cd ../..
$ rake compile
```

#### Install tmc-check ####

```
$ sudo apt-get install check
$ cd tmc-sandbox/uml/output/tmc-check
$ rvmsudo make rubygems install clean
```

#### Run the test suite ####
In the tmc-server root directory run
```
$ rvmsudo rake spec
```

### Post-install instructions ###

#### Development setup ####
Use `script/dev_env` to start the server in [screen](http://www.gnu.org/software/screen/). Please read through the file, if you are interested in the procedure behind starting the service.

In screen, press `Ctrl+A` and then a number key to switch between tabs. To stop the dev environment, press `Ctrl+C`, wait a bit, then press `Q`. Repeat until all tabs are closed.

The default user account is `admin`/`admin`.

### Production setup ###

To enable pghero stats (optional), add the following lines to postgresql.conf:
```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```

1. Recheck your comet server config in `site.yml` and then do `rvmsudo rake comet:config:update`.
2. Install init scripts: `rvmsudo rake comet:init:install`, `rvmsudo rake background_daemon:init:install`.
3. Start the services: `sudo /etc/init.d/tmc-comet start`, `sudo /etc/init.d/tmc-background-daemon start`.
4. If you use Apache, then make sure `public/` and `tmp/` are readable and install [mod_xsendfile](https://tn123.org/mod_xsendfile/). Configure XSendFilePath to the `tmp/cache` directory of the application.

The application should not be deployed into a multithreaded server! It often changes the current working directory, which is a process-specific attribute. Each request should have its process all to itself. If you use Apache with, say, Passenger, then use the prefork MPM.

1. Initialize the database with `env RAILS_ENV=production rake db:reset`
2. Precompile assets with `env RAILS_ENV=production rake assets:precompile`
3. Run `rvmsudo rake init:install` to install the init script for the submission rerunner.
4. Do the same in `ext/tmc-sandbox/web` to install the init script for the sandbox.
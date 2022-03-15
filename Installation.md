## Setup
### Notices before installation

We assume you use [RVM](https://rvm.io/). If you don't, then replace `rvmsudo` with `sudo` during the installation process.  
> Note: Installation instructions works on WSL, but node needs to be installed according to [these](https://docs.microsoft.com/en-us/windows/nodejs/setup-on-wsl2) instructions.
### Installation instructions for Ubuntu
We expect the user to be using account which name is tmc.

#### Install dependencies

Update your package list with
```bash
sudo apt-get update
```
TMC-server dependencies
```bash
sudo apt-get install git build-essential zip unzip imagemagick maven make phantomjs bc postgresql postgresql-contrib chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev xfonts-75dpi libpq-dev
```
Ruby dependencies
```bash
sudo apt-get install git-core curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev
```
RVM dependencies
```bash
sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
```
ext/sandbox dependencies see [rage/sandbox](https://github.com/rage/sandbox) for latest deps  
Requires docker to be installed aswell, read instructions [here](https://docs.docker.com/engine/install/ubuntu/).
```
sudo apt-get install tar zstd moreutils nodejs
```

Install [wkhtmltopdf](https://github.com/pdfkit/PDFKit/wiki/Installing-WKHTMLTOPDF) for course certificate generation.

### Install ruby via RVM
#### Install RVM as multi-user install

:exclamation: If you want to install RVM as a single-user installation, please see [RVM installation instructions](https://rvm.io/rvm/install).

```bash
sudo gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -L https://get.rvm.io | sudo bash -s stable
source /etc/profile.d/rvm.sh
```

Add your own user to RVM group and install Ruby

```bash
sudo adduser <logged-user> rvm
```

Quote from [https://rvm.io/support/troubleshooting#sudo](https://rvm.io/support/troubleshooting#sudo)
> Note: Users **must** log out and back in to gain rvm group membership because group memberships are only evaluated by the operating system at initial login time.

Install ruby

```bash
rvm install 2.6.0
rvm use 2.6.0 --default
gem install bundler
```

### PostgreSQL
#### Create postgres user

Run following command and when prompted give **tmc** as a password, if you want to use another username or stronger password change them into **config/database.local.yml**.

```bash
sudo su postgres
createuser tmc -s -P
```

If you cannot run the above command, you can also create the user manually

```bash
sudo -u postgres
psql -c "CREATE USER tmc WITH SUPERUSER CREATEUSER CREATEDB PASSWORD 'tmc';"
```
:exclamation: Superuser access is useful for dev environment, but discouraged for production.

#### Set PostgreSQL to authenticate with md5 instead of local

This is needed for local postgresql installation, as by default the tests are ran as root bc of the sandbox...

Locate the **pg_hba.conf** file with `locate pg_hba.conf`. The file should be located */etc/postgresql/<version number>/main/pg_hba.conf*. You need root privileges to edit the file. Around line 90 change
```markup
# "local" is for Unix domain socket connections only
local   all             all                                     peer
```
to
```markup
# "local" is for Unix domain socket connections only
local   all             all                                     md5
```
**important** run
```bash
service postgresql restart
```
after to implement changes

### TMC-server installation
#### Clone the TMC repository

```bash
git clone https://github.com/testmycode/tmc-server.git
cd tmc-server
```

```bash
bundle install
```

:exclamation: If you are not using a github account, replace the repository submodule URLs with a HTTPS URL in .git/config e.g. `https://github.com/testmycode/tmc-langs.git`
```bash
git submodule update --init --recursive
```

You can view the site settings from the file `config/site.defaults.yml`. If you want to change the settings for the site, create a new file `config/site.yml` and define the changes there.  
> Note: You do not need to copy the entire file. Settings not in `site.yml` will be looked up from `site.defaults.yml`.  
:exclamation: For development environment you can run command `cp config/site.dev.yml config/site.yml`

Initialize the database with `bin/rake db:create db:migrate`
Note: run `bin/rake db:seed` to initialize admin account

#### Install sandbox dependencies

```bash
cd ext/sandbox
npm ci
```

#### Run the test suite
In the tmc-server root directory run
```bash
bin/rake spec
```

#### Verify code style (optional)

```bash
bundle exec rubocop
```

### Post-install instructions

To enable pghero stats (optional), add the following lines to `postgresql.conf`:
```markup
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```

#### Development setup
Use `script/dev_env` to start the server in [screen](http://www.gnu.org/software/screen/). Please read through the file, if you are interested in the procedure behind starting the service.

In screen, press `Ctrl+A` and then a number key to switch between tabs. To stop the dev environment, press `Ctrl+C`, wait a bit, then press `Q`. Repeat until all tabs are closed.

The default admin account is `admin`/`admin`.
The default user account is `test`/`test`.

### Production setup

:exclamation: Production setup instructions are outdated.

1. Recheck your comet server config in `site.yml` and then do `rvmsudo rake comet:config:update`.
2. Install init scripts: `rvmsudo rake comet:init:install`, `rvmsudo rake background_daemon:init:install`.
3. Start the services: `sudo /etc/init.d/tmc-comet start`, `sudo /etc/init.d/tmc-background-daemon start`.
4. If you use Apache, then make sure `public/` and `tmp/` are readable and install [mod_xsendfile](https://tn123.org/mod_xsendfile/). Configure XSendFilePath to the `tmp/cache` directory of the application.

The application should not be deployed into a multithreaded server! It often changes the current working directory, which is a process-specific attribute. Each request should have its process all to itself. If you use Apache with, say, Passenger, then use the prefork MPM.

1. Initialize the database with `env RAILS_ENV=production rake db:reset`
2. Precompile assets with `env RAILS_ENV=production rake assets:precompile`
3. Run `rvmsudo rake init:install` to install the init script for the submission rerunner.
4. Do the same in `ext/tmc-sandbox/web` to install the init script for the sandbox.

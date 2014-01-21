# Test My Code server #

*Test My Code* ("TMC") is a tool to automate most of the exercise checking when teaching programming.
It runs code submitted by students, gives feedback if tests fail and maintains a scoreboard.
This allows for lots of small exercises without the need for course instructors to manually go through all of them.

The system has been used with great success by the [University of Helsinki CS Dept.](http://cs.helsinki.fi/) in
several elementary programming and data structures courses with hundreds of users.


## Setup ##

Very rough setup instructions below.

### System Dependencies ###

The following programs should be installed first: `git`, `zip`, `unzip`, `convert` (from ImageMagick), `javac`, `java`, `ant`, `mvn`, `gcc`, `make`, `bc`.

An X server is currently needed for tests to pass (required by [capybara-webkit](https://github.com/thoughtbot/capybara-webkit)). `Xvfb` will do, but remember to set your `DISPLAY`.

### Setup ###

We assume you use [RVM](https://rvm.io/). If you don't, then replace `rvmsudo` with `sudo` below.
(note: RVM 1.17.x may have some [problems with rvmsudo](http://stackoverflow.com/questions/13765520/rvmsudo-command-not-working-properly))

1. Download submodules with `git submodule update --init --recursive`
2. Install dependencies with `gem install bundler && bundle install`
3. Edit `config/site.yml` based on `config/site.defaults.yml`.
4. Install PostgreSQL 9.x+. See `config/database.yml` for database settings.
5. Initialize the database with `env RAILS_ENV=production rake db:reset`
6. Go to `ext/tmc-sandbox` and compile it with `sudo make`. See its readme for dependencies.
7. Go to `ext/tmc-sandbox/web` and install dependencies with `bundle install`. Compile extensions with `rake ext` and run tests with `rvmsudo rake test`.
8. Compile the other stuff in `ext` by doing `rake compile`.
9. Install tmc-check locally by running `rvmsudo make -C ext/tmc-check rubygems install clean`.
10. Run the test suite with `rvmsudo rake spec`.

After you get the test suite to pass, you can set up background services.

1. Recheck your comet server config in `site.yml` and then do `rvmsudo rake comet:config:update`.
2. Install init scripts: `rvmsudo rake comet:init:install`, `rvmsudo rake reprocessor:init:install`.
3. Start the services: `sudo /etc/init.d/tmc-comet start`, `sudo /etc/init.d/tmc-submission-reprocessor start`.
4. If you use Apache, then make sure `public/` and `tmp/` are readable and install [mod_xsendfile](https://tn123.org/mod_xsendfile/). Configure XSendFilePath to the `tmp/cache` directory of the application.

The application should not be deployed into a multithreaded server! It often changes the current working directory, which is a process-specific attribute. Each request should have its process all to itself. If you use Apache with, say, Passenger, then use the prefork MPM.

### Startup ###

1. `rails server` or some other RoR setup.
2. Go to `ext/tmc-sandbox/web` and do `rackup --port 3001` or some other Rack setup.
3. `rake dev:comet:run`
4. `script/submission_reprocessor start`

Alternatively use `script/dev_env` to do all of the above in
[screen](http://www.gnu.org/software/screen/).

The default user account is `admin`/`admin`.

### Production setup ###

1. Run `rvmsudo rake init:install` to install the init script for the submission rerunner.
2. Do the same in `ext/tmc-sandbox/web` to install the init script for the sandbox.

## Credits ##

The project started as a Software Engineering Lab project at the [University of Helsinki CS Dept.](http://cs.helsinki.fi/) but has since been gradually almost completely rewritten. The original authors of the server component were

- Patrik Marjanen
- Jarno Mynttinen
- Martti Rannanjärvi ([mrannanj](https://github.com/mrannanj))
- Katri Rantanen

Another team wrote a [NetBeans plugin](https://github.com/testmycode/tmc-netbeans) for the system.

The course instructor and current maintainer of the project is Martin Pärtel ([mpartel](https://github.com/mpartel)). Other closely involved instructors were

- Matti Luukkainen ([mluukkai](https://github.com/mluukkai))
- Antti Laaksonen
- Arto Vihavainen
- Jaakko Kurhila

The system was improved and C language support was added in another SE lab project by

- Jarmo Isotalo ([jamox](https://github.com/jamox))
- Tony Kovanen ([rase-](https://github.com/rase-))
- Kalle Viiri ([Kviiri](https://github.com/Kviiri))


## License ##

[GPLv2](http://www.gnu.org/licenses/gpl-2.0.html)


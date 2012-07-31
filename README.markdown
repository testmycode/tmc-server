# Test My Code server #

*Test My Code* ("TMC") is a tool to automate most of the exercise checking when teaching programming. It runs code submitted by students, gives feedback if tests fail and maintains a scoreboard. This allows for lots of small exercises without the need for course instructors to manually go through all of them.

The system has been used by the [University of Helsinki CS Dept.](http://cs.helsinki.fi/) in an elementary programming course. The course had almost 200 participants and TMC saved course assistants a lot of work while giving students instant feedback for many exercises. Development continued and now TMC is used to check all exercises for over 400 students on two elementary courses and one data structures course.


## Setup ##

### System Dependencies ###

The following programs should be installed first: `git`, `zip`, `unzip`, `convert` (from ImageMagick), `javac`, `java`, `ant`, `mvn`.

An X server is currently needed for tests to pass (required by [capybara-webkit](https://github.com/thoughtbot/capybara-webkit)). `Xvfb` will do, but remember to set your `DISPLAY`.

### One-time setup ###

1. Download submodules with `git submodule update --init --recursive`
2. Install dependencies with `gem install bundler && bundle install`
3. Edit `config/site.yml` based on `config/site.defaults.yml`.
4. Install PostgreSQL 9.x+. See `config/database.yml` for database settings.
5. Initialize the database with `env RAILS_ENV=production rake db:reset`
6. Go to `ext/tmc-sandbox` and compile it with `sudo make`. See its readme for dependencies.
7. Go to `ext/tmc-sandbox/web` and install dependencies with `bundle install`. Run tests with `rake test`.
8. Run the test suite with `rake spec`.
9. If you use Apache, then make sure `public/` and `tmp/` are readable and install [mod_xsendfile](https://tn123.org/mod_xsendfile/). Configure XSendFilePath to the `tmp/cache` directory of the application.

The application should not be deployed into a multithreaded server! It often changes the current working directory, which is a process-specific attribute. Each request should have its process all to itself. If you use Apache with, say, Passenger, then use the prefork MPM.

### Startup ###

1. `rails server` or some other RoR setup.
2. Go to `ext/tmc-sandbox/web` and do `rackup --port 3001` or some other Rack setup.
3. `script/submission_reprocessor start`
4. The default user account is `admin`/`admin`.


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


## License ##

[GPLv2](http://www.gnu.org/licenses/gpl-2.0.html)


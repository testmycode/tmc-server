# Test My Code server #

*Test My Code* ("TMC") is a tool to automate most of the exercise checking when teaching programming.
It runs code submitted by students, gives feedback if tests fail and maintains a scoreboard.
This allows for lots of small exercises without the need for course instructors to manually go through all of them.

The system has been used with great success by the [University of Helsinki CS Dept.](http://cs.helsinki.fi/) in
several elementary programming and data structures courses with hundreds of users.

## Usermanual ##
Automatically built usermanual can be viewed at: http://testmycode-usermanual.github.io

## Setup ##

For setup and startup instructions, please see the [installation guide](Installation.md).

## Running dev in Docker ##

Before running dev in docker one needs to do some manual setup:
- `git submodule update --init --recursive`
- `rake compile`
To build neccessary external dependencies.

The dev docker mounts local folder to the image and allows code changes to be visible in real time.
Dev environment can be run with docker-compose: `docker-compose -f docker-compose-dev.yml up`

To run rails migrations etc you may exec those like this: `docker exec -it tmcserver_dev_1 rake db:create db:migrate db:seed`.

The container name can be checked with `docker ps`


## Running tests in parallel ##

Tests can be run parallel with docker-compose. This expects you to have functioning docker and docker-compose setup.

For collecting test results from different testruns you need to clone and use this: https://github.com/jamox/remote_rspec_aggregator
Basically you wan't to clone the repo and `bundle install` once and run `rackup --host 0.0.0.0 --port 4567` to have it accessible from the testruns running in docker.

Once it's running run all tests by executing `env REPORT_URL=<IP OF DOCKER INTERFACE> docker-compose up --build` and see test results flowing to rspec test result aggregator.

The test environment builds hermetic images for each testrun by including all source files to the testrun container. Thus we need to use `--build` (or trust docker to detect changes in directories) to run tests for newest code.


## Credits ##

Current maintainers of the project are
- Martin Pärtel ([mpartel](https://github.com/mpartel))
- Jarmo Isotalo ([jamox](https://github.com/jamox))

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

Checkstyle-support was integrated by

- Kenny Heinonen ([kennyhei](https://github.com/kennyhei/))
- Kasper Hirvikoski ([kasper](https://github.com/kasper/))
- Jarmo Isotalo ([jamox](https://github.com/jamox/))
- Joni Salmi ([josalmi](https://github.com/josalmi/))

## License ##

[GPLv2](http://www.gnu.org/licenses/gpl-2.0.html)


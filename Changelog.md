## 2016-01-29

* Started using [tmc-langs](https://github.com/testmycode/tmc-langs) for processing exercises. NOTE: for maven projects this requires installation of maven3 and having $M3_HOME set properly.

## 2015-06-06

* Added support for students to generate certificates for accomplished courses. Note, this requires installation of
  [wkhtmltopdf](https://github.com/pdfkit/PDFKit/wiki/Installing-WKHTMLTOPDF) use the first option to install (for ubuntu 10.04 lts version from apt is too old).

## 2015-02-22

* Added option to disable code review request action from clients.
* Added option to disable run tests locally action from clients.

### 2015-01-18

* Upgraded Rails to 4.1.
* Enabled asset pipeline (see app/assets/ and vendor/assets/).
* Code style improvements: converted HashStyle from hash rocket to JSON-style, removed trailing whitespaces, extra blank lines, added trailing blank lines and made other small improvements.
* Upgraded jquery-rails to 3.1 and database_cleaner to 1.3.
* Removed act_as_api (#197).

### 2014-12-10

* [SECURITY] Fixed vulnerability where symlinks in zips could be used to read any file on the server where the server had read access.

### 2014-12-09

* Upgraded FactoryGirl to 4.5 and converted to new syntax.

### 2014-12-03

* Upgraded RSpec to 3.1 and converted existing specs from should-syntax to new expectation-syntax.
* Switched Selenium to Poltergeist (PhantomJS) for headless browser testing. You need to install PhantomJS (at least version 1.8.1) to your path, see http://phantomjs.org.
* Upgraded Capybara to 2.4.
* Switched CanCan to CanCanCan for Rails 4 support.

### 2014-11-24

* Removed pg_comment for Rails 4 support.

### 2014-10-07

* Cleaned up how stats are aggregated, admin or test users are no longer
  includes to stats. Thus making stats more realistic.

### 2014-09-24

* Extra student files also shown in the submitted files view

### 2014-09-21

* Added pghero to get stats from database

    Add following lines to postgresql.conf to enable
    ```
    shared_preload_libraries = 'pg_stat_statements'
    pg_stat_statements.track = all
    ```
    Requires postgresql 9.2 or newer

    pghero stats can be accessed from /pghero

* Made valgrind fails configurable with `valgrind_strategy` in
  metadata.yml

### 2014-09-04

* Made it possible to set course-specific options in metadata.yml and course_options.yml,
  enabling running multiple courses with different configs from the same repo.

### 2014-08-30

* Added API courses/:coursename/exercise_status/:username.json to get
  individual details for course completion status.

### 2014-08-17

* `metadata.yml` now accepts a `runtime_params` option that allows setting arbitrary JVM parameters.
  These are served to the NB plugin and used in the sandbox.

### 2014-08-14

* Added option to download submissions with test/ and nbproject/ folders
  thus making debugging submitted code easier for TAs.

### 2014-08-03

* Optimized course refresher. Unlock conditions are now only calculated on demand,
  so the course refreshed doesn't spend any time on them any more.
  Course refresh should now take just a few minutes.
* Optimized Course#show.

### 2014-07-30

* Started to support real HTTP Basic auth

### 2014-07-27

* Added support for running Checkstyle for Java submissions
* Refactored Submission#show

  Now we have tabbed view for Logs, Files, Stderr and Stdout instead of having
  those stacked or on separate pages.

### 2014-03-13

* Pastes expire by default in a few hours

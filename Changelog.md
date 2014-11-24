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

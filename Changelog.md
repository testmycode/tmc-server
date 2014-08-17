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

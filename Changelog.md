### 2014-08-14

* Added option to download submissions with test/ and nbproject/ folders
  thus making debugging submitted code easier for TAs.

### 2014-08-03

* Optimized course refresher, started to calculate unlock conditions lazily
  and more optimized. Thus course refresh should happen in just a few
  minutes. Also Course#show is much faster

### 2014-07-30

* Started to support real HTTP Basic auth

### 2014-07-27

* Added support for running Checkstyle for Java submissions
* Refactored Submission#show

  Now we have tabbed view for Logs, Files, Stderr and Stdout instead of having
  those stacked or on separate pages.

### 2014-03-13

* Pastes expire by default in a few hours

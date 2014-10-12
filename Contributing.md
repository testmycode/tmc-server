Tmc-server is a volunteer effort. We encourage you to pitch in!

### Contributing to tmc-server

1) Fork tmc-server.

2) Install tmc-server and its dependencies by following installation
instructions from Readme.md

3) Create your own branch for your fix or feature. We prefer descriptive
branch names.

4) Write the code and tests.

5) Remember to run whole test suite.

* Submit your pull request early to get feedback and new implementation
ideas earlier.

* For each pull request it often takes multiple iterations of codereview
form maintainers so better to start early for best developer experience.

* Usually it takes at most two to three days for a code review, however
with bigger changes time might be longer.


* During this progress we appreciate you to keep maintainers in loop with
your development and implementation. We may give you helpful tips during
the progress as well as early critique.
Especially when refactoring start by discussing about your idea with us.


### Coding conventions

Tmc-server follows a simple set of coding style conventions:

* Two spaces, no tabs (for indentation).
* No trailing whitespace. Blank lines should not have any spaces.
* Indent after private/protected.
* Use Ruby >= 1.9 syntax for hashes. Prefer { a: :b } over { :a => :b }.
* Prefer &&/|| over and/or.
* Prefer class << self over self.method for class methods.
* Use MyClass.my_method(my_arg) not my_method( my_arg ) or my_method
my_arg.
* Use a = b and not a=b.
* Prefer method { do_stuff } instead of method{do_stuff} for single-line
blocks.
* Follow the conventions in the source you see used already.

The above are guidelines - please use your best judgment in using them.
Most importantly keep using the same coding standards as already used in
that particular file.


### Reporting issues

We accept only issues reported in GitHub. However before reporting
issues to GitHub discussed with maintainers is advised.

Do a search in GitHub under Issues in case it has already been reported.
If you do not find any issue addressing it you may proceed to open a new
one. (In case of security issues, alert maintainers in private, don't
post it to out public issue tracker.)


Your issue report should contain a title and a clear description of the
issue at the bare minimum. You should include as much relevant
information as possible and should at least post a code sample that
demonstrates the issue. It would be even better if you could include a
unit test that shows how the expected behavior is not occurring. Your
goal should be to make it easy for yourself - and others - to replicate
the bug and figure out a fix.

### Creating feature requests

We accept also feature requests as issues reported in GitHub, the issue
should clearly indicate that it is a feature request.

However it is suggested to first discuss with maintainers about your
feature request.

### Testing others pull requests

To apply someone's changes you need first to create a dedicated branch:

``` shell
$ git checkout -b testing_branch
```

Then you can use their remote branch to update your codebase. For
example, let's say the GitHub user Jamox has forked and pushed to a
topic branch "feature" located at https://github.com/Jamox/tmc-server.
``` shell
$ git remote add Jamox git://github.com/Jamox/tmc-server.git
$ git pull Jamox feature
```
After applying their branch, test it out!

### Tips running tests

It may take some time to run whole test suite, thus while developing one
may find beneficial to run just single test cases or tests from one
file.

##### To run all tests
`rvmsudo rake spec`

##### To run tests from one file
`rvmsudo rake spec SPEC=spec/integration/student_usecases_spec.rb`

##### To run one test case
`rvmsudo rake spec SPEC=spec/integration/student_usecases_spec.rb:175`

##### To add flags for rspec, use SPEC_OPTS
`rvmsudo rake spec SPEC=spec/controllers/exercise_status_controller.rb
SPEC_OPTS="--fail-fast"`

## TMC-server

Check http://testmycode.github.io for contribution guidelines!



## Git hooks

The Nix dev shell (`nix develop`) installs [lefthook](https://lefthook.dev) hooks.
On commit, `rubocop --autocorrect` runs on the staged Ruby files and the fixes are re-staged.
It never blocks a commit. Skip it with `LEFTHOOK=0 git commit ...`.

Before opening a PR, run `bin/branch-ready-checks` (rubocop, brakeman, `srb tc`, and the tapioca verifications; needs a database).

## Tips running tests

It may take some time to run whole test suite, thus while developing one
may find beneficial to run just single test cases or tests from one
file.

##### To run all code style validations
`bundle exec rubocop`

##### To run the security scan
`bundle exec brakeman`. Record a reviewed false positive, with a note saying why it is safe, through `bundle exec brakeman -I`.

##### To run all tests
`rvmsudo rake spec`

##### To run tests from one file
`rvmsudo rake spec SPEC=spec/integration/student_usecases_spec.rb`

##### To run one test case
`rvmsudo rake spec SPEC=spec/integration/student_usecases_spec.rb:175`

##### To add flags for rspec, use SPEC_OPTS
`rvmsudo rake spec SPEC=spec/controllers/exercise_status_controller.rb
SPEC_OPTS="--fail-fast"`

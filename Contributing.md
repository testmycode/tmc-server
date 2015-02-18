## TMC-server

Check http://testmycode.github.io for contribution guidelines!



## Tips running tests

It may take some time to run whole test suite, thus while developing one
may find beneficial to run just single test cases or tests from one
file.

##### To run all code style validations
`bundle exec rubocop`

##### To run all tests
`rvmsudo rake spec`

##### To run tests from one file
`rvmsudo rake spec SPEC=spec/integration/student_usecases_spec.rb`

##### To run one test case
`rvmsudo rake spec SPEC=spec/integration/student_usecases_spec.rb:175`

##### To add flags for rspec, use SPEC_OPTS
`rvmsudo rake spec SPEC=spec/controllers/exercise_status_controller.rb
SPEC_OPTS="--fail-fast"`

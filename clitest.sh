#!/bin/bash -v
java -jar ext/tmc-langs/tmc-langs-cli/target/tmc-langs-cli-1.0-SNAPSHOT.jar prepare-stubs spec/fixtures/exercises/SimpleExercise/ tempsolution
ls -laR tempsolution


# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'shellwords'
require 'system_commands'

# There is some functionality in common with JavaSimple. We mostly only test that in java_simple_spec.rb.
describe SubmissionPackager::JavaMaven do
  include GitTestActions
  include SystemCommands

  before :each do
    @setup = SubmissionTestSetup.new(exercise_name: 'MavenExercise')
    @course = @setup.course
    @repo = @setup.repo
    @exercise_project = @setup.exercise_project
    @exercise = @setup.exercise
    @user = @setup.user
    @submission = @setup.submission

    @tar_path = Pathname.new('result.tar').expand_path.to_s
  end

  def package_it
    SubmissionPackager.get(@exercise).package_submission(@exercise, @exercise_project.zip_path, @tar_path)
  end

  it 'should package the submission in a tar file with tests from the repo' do
    @exercise_project.solve_all
    @exercise_project.make_zip(src_only: false)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File).to exist('src/main/java/SimpleStuff.java')
        expect(File.read('src/main/java/SimpleStuff.java')).to eq(File.read(@exercise_project.path + '/src/main/java/SimpleStuff.java'))

        expect(File).to exist('pom.xml')
        expect(File).to exist('src/test/java/SimpleTest.java')
        expect(File).to exist('src/test/java/SimpleHiddenTest.java')
      end
    end
  end

  it 'can handle a zip with no parent directory over the src directory' do
    @exercise_project.solve_all
    Dir.chdir(@exercise_project.path) do
      system!("zip -q -0 -r #{@exercise_project.zip_path} src")
    end

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File).to exist('src/main/java/SimpleStuff.java')
        expect(File.read('src/main/java/SimpleStuff.java')).to eq(File.read(@exercise_project.path + '/src/main/java/SimpleStuff.java'))
      end
    end
  end

  it 'does not use any tests from the submission' do
    @exercise_project.solve_all
    File.open(@exercise_project.path + '/src/test/java/SimpleTest.java', 'w') { |f| f.write('foo') }
    File.open(@exercise_project.path + '/src/test/java/NewTest.java', 'w') { |f| f.write('bar') }
    @exercise_project.make_zip(src_only: false)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File.read('src/test/java/SimpleTest.java')).to eq(File.read(@exercise.clone_path + '/src/test/java/SimpleTest.java'))
        expect(File).not_to exist('src/test/java/NewTest.java')
      end
    end
  end

  it "uses tests from the submission if specified in .tmcproject.yml's extra_student_files" do
    File.open("#{@exercise.clone_path}/.tmcproject.yml", 'w') do |f|
      f.write("extra_student_files:\n  - src/test/java/SimpleTest.java\n  - src/test/java/NewTest.java")
    end

    @exercise_project.solve_all
    File.open(@exercise_project.path + '/src/test/java/SimpleTest.java', 'w') { |f| f.write('foo') }
    File.open(@exercise_project.path + '/src/test/java/NewTest.java', 'w') { |f| f.write('bar') }
    @exercise_project.make_zip(src_only: false)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File.read('src/test/java/SimpleTest.java')).to eq('foo')
        expect(File.read('src/test/java/NewTest.java')).to eq('bar')
      end
    end
  end

  it 'does not use .tmcproject.yml from the submission' do
    @exercise_project.solve_all
    File.open("#{@exercise_project.path}/.tmcproject.yml", 'w') do |f|
      f.write("extra_student_files:\n  - src/test/java/SimpleTest.java\n  - src/test/java/NewTest.java")
    end
    File.open(@exercise_project.path + '/src/test/java/SimpleTest.java', 'w') { |f| f.write('foo') }
    File.open(@exercise_project.path + '/src/test/java/NewTest.java', 'w') { |f| f.write('bar') }
    @exercise_project.make_zip(src_only: false)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File.read('src/test/java/SimpleTest.java')).to eq(File.read(@exercise.clone_path + '/src/test/java/SimpleTest.java'))
        expect(File).not_to exist('src/test/java/NewTest.java')
        expect(File).not_to exist('.tmcproject.yml')
      end
    end
  end

  it 'includes the .tmcrc file if present' do
    File.open("#{@exercise.clone_path}/.tmcrc", 'w') do |f|
      f.write('hello')
    end

    @exercise_project.solve_all
    @exercise_project.make_zip(src_only: false)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File).to exist('.tmcrc')
        expect(File.read('.tmcrc')).to eq('hello')
      end
    end
  end

  it 'does not use .tmcrc from the submission' do
    @exercise_project.solve_all
    File.open("#{@exercise_project.path}/.tmcrc", 'w') do |f|
      f.write('hello')
    end
    @exercise_project.make_zip(src_only: false)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File).not_to exist('.tmcrc')
      end
    end
  end

  it 'includes files in the root dir from the repo' do
    @repo.write_file('MavenExercise/foo.txt', 'repohello')
    @repo.add_commit_push
    @course.refresh(user.id)

    @exercise_project.solve_all
    File.open("#{@exercise_project.path}/foo.txt", 'w') do |f|
      f.write('submissionhello')
    end
    @exercise_project.make_zip(src_only: true)

    package_it

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        expect(File).to exist('foo.txt')
        expect(File.read('foo.txt')).to eq('repohello')
      end
    end
  end

  describe 'tmc-run script added to the archive' do
    it 'should run mvn tmc:test' do
      pending 'TMC-langs migration will make this irrelevant'
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          sh! ['tar', 'xf', @tar_path]

          begin
            sh! ['env', "JAVA_RAM_KB=#{64 * 1024}", './tmc-run']
          rescue StandardError
            if File.exist?('test_output.txt')
              raise($!.message + "\n\n" + "The contents of test_output.txt:\n" + File.read('test_output.txt'))
            else
              raise
            end
          end

          expect(File).to exist('target/classes/SimpleStuff.class')
          expect(File).to exist('target/test-classes/SimpleTest.class')
          expect(File).to exist('test_output.txt')
          expect(File.read('test_output.txt')).to include('"status":"PASSED"')
        end
      end
    end

    it 'should report compilation errors in test_output.txt with exit code 101' do
      pending 'TMC-langs migration will make this irrelevant'
      @exercise_project.introduce_compilation_error
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          sh! ['tar', 'xf', @tar_path]
          `env JAVA_RAM_KB=#{64 * 1024} ./tmc-run`
          expect($?.exitstatus).to eq(101)
          expect(File).to exist('test_output.txt')

          output = File.read('test_output.txt')
          expect(output).to include('COMPILATION ERROR')
          expect(output).to include('BUILD FAILURE')
        end
      end
    end
  end
end

require 'spec_helper'
require 'tmpdir'
require 'shellwords'
require 'system_commands'

describe SubmissionPackager::JavaSimple do
  include GitTestActions
  include SystemCommands

  before :each do
    @setup = SubmissionTestSetup.new(exercise_name: 'SimpleExercise')
    @course = @setup.course
    @repo = @setup.repo
    @exercise_project = @setup.exercise_project
    @exercise = @setup.exercise
    @user = @setup.user
    @submission = @setup.submission

    @tar_path = Pathname.new('result.tar').expand_path.to_s
    @zip_path = Pathname.new('result.zip').expand_path.to_s
  end

  def package_it(extra_params = {})
    SubmissionPackager.get(@exercise).package_submission(@exercise, @exercise_project.zip_path, @tar_path, extra_params)
  end

  def package_it_for_download(extra_params = {})
    config = { tests_from_stub: true, format: :zip }
    SubmissionPackager.get(@exercise).package_submission(@exercise, @exercise_project.zip_path, @zip_path, extra_params, config)
  end

  describe 'tar' do
    it 'packages the submission in a tar file with tests from the repo' do
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File).to exist('src/SimpleStuff.java')
          expect(File.read('src/SimpleStuff.java')).to eq(File.read(@exercise_project.path + '/src/SimpleStuff.java'))

          expect(File).to exist('test/SimpleTest.java')
          expect(File).to exist('test/SimpleHiddenTest.java')
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
          expect(File).to exist('src/SimpleStuff.java')
          expect(File.read('src/SimpleStuff.java')).to eq(File.read(@exercise_project.path + '/src/SimpleStuff.java'))
        end
      end
    end

    it 'does not use any tests from the submission' do
      @exercise_project.solve_all
      File.open(@exercise_project.path + '/test/SimpleTest.java', 'w') { |f| f.write('foo') }
      File.open(@exercise_project.path + '/test/NewTest.java', 'w') { |f| f.write('bar') }
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File.read('test/SimpleTest.java')).to eq(File.read(@exercise.clone_path + '/test/SimpleTest.java'))
          expect(File).not_to exist('test/NewTest.java')
        end
      end
    end

    it "uses tests from the submission if specified in .tmcproject.yml's extra_student_files" do
      File.open("#{@exercise.clone_path}/.tmcproject.yml", 'w') do |f|
        f.write("extra_student_files:\n  - test/SimpleTest.java\n  - test/NewTest.java")
      end

      @exercise_project.solve_all
      File.open(@exercise_project.path + '/test/SimpleTest.java', 'w') { |f| f.write('foo') }
      File.open(@exercise_project.path + '/test/NewTest.java', 'w') { |f| f.write('bar') }
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File.read('test/SimpleTest.java')).to eq('foo')
          expect(File.read('test/NewTest.java')).to eq('bar')
        end
      end
    end

    it 'does not use .tmcproject.yml from the submission' do
      @exercise_project.solve_all
      File.open("#{@exercise_project.path}/.tmcproject.yml", 'w') do |f|
        f.write("extra_student_files:\n  - test/SimpleTest.java\n  - test/NewTest.java")
      end
      File.open(@exercise_project.path + '/test/SimpleTest.java', 'w') { |f| f.write('foo') }
      File.open(@exercise_project.path + '/test/NewTest.java', 'w') { |f| f.write('bar') }
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File.read('test/SimpleTest.java')).to eq(File.read(@exercise.clone_path + '/test/SimpleTest.java'))
          expect(File).not_to exist('test/NewTest.java')
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

    it 'adds tmc-junit-runner.jar and its deps to lib/testrunner/' do
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File.read('lib/testrunner/tmc-junit-runner.jar')).to eq(File.read(TmcJunitRunner.get.jar_path))
          for original_path in TmcJunitRunner.get.lib_paths
            expect(File.read("lib/testrunner/#{original_path.basename}")).to eq(File.read(original_path))
          end
        end
      end
    end

    # TODO(jamo) it doesn't really test for the deps
    it 'adds tmc-checkstyle-runner.jar to lib/testrunner/' do
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File.read('checkstyle-runner/tmc-checkstyle-runner.jar')).to eq(File.read(TmcCheckstyleRunner.get.jar_path))
        end
      end
    end

    it 'includes files in the root dir from the repo' do
      @repo.write_file('SimpleExercise/foo.txt', 'repohello')
      @repo.add_commit_push
      @course.refresh

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

    it 'writes extra parameters into .tmcparams' do
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it(foo: :bar)

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File).to exist('.tmcparams')
          expect(File.readlines('.tmcparams').map(&:strip)).to include 'export foo=bar'
        end
      end
    end

    it 'writes runtime params into .tmcparams' do
      @exercise.runtime_params = ActiveSupport::JSON.encode(['-Xss8M', '-verbose:gc'])
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `tar xf #{Shellwords.escape(@tar_path)}`
          expect(File).to exist('.tmcparams')
          expect(File.readlines('.tmcparams').map(&:strip)).to include 'export runtime_params=(-Xss8M -verbose:gc)'
        end
      end
    end

    describe 'tmc-run script added to the archive' do
      it 'should compile and run the submission' do
        @exercise_project.solve_all
        @exercise_project.make_zip(src_only: false)

        package_it

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            sh! ['tar', 'xf', @tar_path]
            expect(File).not_to exist('classes/main/SimpleStuff.class')
            expect(File).not_to exist('test_output.txt')

            begin
              sh! ['env', "JAVA_RAM_KB=#{64 * 1024}", './tmc-run']
            rescue
              if File.exist?('test_output.txt')
                raise($!.message + "\n\n" + "The contents of test_output.txt:\n" + File.read('test_output.txt'))
              else
                raise
              end
            end

            expect(File).to exist('classes/main/SimpleStuff.class')
            expect(File).to exist('test_output.txt')
            expect(File.read('test_output.txt')).to include('"status":"PASSED"')
          end
        end
      end

      it 'sould report compilation errors in test_output.txt with exit code 101' do
        @exercise_project.introduce_compilation_error
        @exercise_project.make_zip(src_only: false)

        package_it

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            sh! ['tar', 'xf', @tar_path]
            expect(File).not_to exist('classes/main/SimpleStuff.class')
            expect(File).not_to exist('test_output.txt')
            `env JAVA_RAM_KB=#{64 * 1024} ./tmc-run`
            expect($?.exitstatus).to eq(101)
            expect(File).to exist('test_output.txt')

            output = File.read('test_output.txt')
            expect(output).to include('compiler should fail here')
          end
        end
      end

      it 'should source .tmcrc' do
        File.open("#{@exercise.clone_path}/.tmcrc", 'w') do |f|
          f.write('echo $PROJECT_TYPE > lol.txt')
        end

        @exercise_project.solve_all
        @exercise_project.make_zip(src_only: false)

        package_it

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            sh! ['tar', 'xf', @tar_path]

            begin
              sh! ['env', "JAVA_RAM_KB=#{64 * 1024}", './tmc-run']
            rescue
              if File.exist?('test_output.txt')
                raise($!.message + "\n\n" + "The contents of test_output.txt:\n" + File.read('test_output.txt'))
              else
                raise
              end
            end

            expect(File).to exist('lol.txt')
            expect(File.read('lol.txt').strip).to eq('java_simple')
          end
        end
      end
    end
  end

  describe 'zip' do
    it 'packages the submission in a zip file with tests from the repo' do
      @exercise_project.solve_all
      @exercise_project.make_zip(src_only: false)

      package_it_for_download

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `unzip #{Shellwords.escape(@zip_path)}`
          expect(File).to exist('src/SimpleStuff.java')
          expect(File.read('src/SimpleStuff.java')).to eq(File.read(@exercise_project.path + '/src/SimpleStuff.java'))

          expect(File).to exist('test/SimpleTest.java')
          expect(File).not_to exist('test/SimpleHiddenTest.java')
        end
      end
    end

    it 'can handle a zip with no parent directory over the src directory' do
      @exercise_project.solve_all
      Dir.chdir(@exercise_project.path) do
        system!("zip -q -0 -r #{@exercise_project.zip_path} src")
      end

      package_it_for_download

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `unzip #{Shellwords.escape(@zip_path)}`
          expect(File).to exist('src/SimpleStuff.java')
          expect(File.read('src/SimpleStuff.java')).to eq(File.read(@exercise_project.path + '/src/SimpleStuff.java'))
        end
      end
    end

    it "uses tests from the submission if specified in .tmcproject.yml's extra_student_files" do
      File.open("#{@exercise.clone_path}/.tmcproject.yml", 'w') do |f|
        f.write("extra_student_files:\n  - test/SimpleTest.java\n  - test/NewTest.java")
      end

      @exercise_project.solve_all
      File.open(@exercise_project.path + '/test/SimpleTest.java', 'w') { |f| f.write('foo') }
      File.open(@exercise_project.path + '/test/NewTest.java', 'w') { |f| f.write('bar') }
      @exercise_project.make_zip(src_only: false)

      package_it_for_download

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          `unzip #{Shellwords.escape(@zip_path)}`
          expect(File.read('test/SimpleTest.java')).to eq('foo')
          expect(File.read('test/NewTest.java')).to eq('bar')
        end
      end
    end
  end
end

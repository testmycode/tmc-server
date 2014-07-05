require 'shellwords'
require 'maven_project'

# Interface to tmc-junit-runner.
class TmcCheckstyleRunner < MavenProject
  def self.get
    @instance ||= TmcCheckstyleRunner.new
  end

  # Get instances via .get instead
  def initialize
    super("#{::Rails.root}/ext/tmc-checkstyle-runner")
  end

  def jar_and_lib_paths
    [jar_path] + lib_paths
  end

  def package
    pom_file.artifact_group_id
  end

  def jar_path
    package_path
  end

  def classpath
    "#{jar_path}:#{lib_paths.join(':')}"
  end

  def compiled?
    File.exists? jar_path
  end

#  # Use TestScanner.get_test_case_methods instead.
#  def get_test_case_methods(exercise_path)
#    #CTODO
#    #TMCTODO
#    result = []
#    ex_dir = ExerciseDir.get(exercise_path)
#
#    ex_cp = if ex_dir.respond_to? :library_jars
#      ex_dir.library_jars.map(&:to_s).join(':')
#    else
#      ""
#    end
#
#    runner_cp = classpath
#
#    Dir.mktmpdir do |tmpdir|
#      stderr_file = "#{tmpdir}/stderr"
#      cmd = SystemCommands.mk_command([
#        'java',
#        '-cp',
#        runner_cp + ':' + ex_cp,
#        "#{package}.testscanner.TestScanner",
#        ex_dir.path.to_s
#      ])
#
#      output = `#{cmd} 2>#{Shellwords.escape(stderr_file)}`
#
#      if !$?.success?
#        raise File.read(stderr_file)
#      end
#
#      result += parse_test_scanner_output(output)
#    end
#    result
#  end

protected

  def parse_test_scanner_output(output)
    JSON.parse(output).map do |item|
      Hash[item.map {|k,v| [k.underscore.to_sym, v] }]
    end
  end
end


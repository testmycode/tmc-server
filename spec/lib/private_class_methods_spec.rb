# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'exercise_completion_status_generator'
require 'rust_langs_cli_executor'
require 'sandbox_results_saver'
require 'test_run_grader'

describe 'Class-level helpers declared private' do
  {
    ExtraField => %i[config_files load_fields],
    FeedbackAnswer => %i[numeric_answers_query numeric_answer_averages_query numeric_answers_base_query],
    FileStore => %i[tmpdir],
    SiteSetting => %i[settings_from_files settings_files],
    SourceFileList => %i[find_source_files_under find_all_files_under source_file? should_skip_dir? make_path_names_relative sort_source_files],
    Stats => %i[all_regular_users all_nonhidden_exercises get_exercises],
    TmcProjectFile => %i[empty],
    Unlock => %i[refresh_unlocks_impl fast_refresh_unlocks_impl],
    ExerciseCompletionStatusGenerator => %i[completion_status_of_exercise percentage_of_completed_exercises],
    RustLangsCliExecutor => %i[parse_as_JSON langs_executable_path process_prepare_submission_command_output process_refresh_command_output],
    SandboxResultsSaver => %i[handle_tmc_langs_output decode_test_output],
    TestRunGrader => %i[create_test_case_runs award_points points_from_test_results to_json_or_null],
    RemoteSandboxForTesting => %i[result_queue copy_server_instance]
  }.each do |owner, methods|
    methods.each do |method|
      it "#{owner}.#{method} is private" do
        expect(owner.private_methods).to include(method)
      end
    end
  end

  it 'keeps the helpers used outside their class public' do
    expect(FeedbackQuestion).to respond_to(:intrange_regex)
    expect(UnlockSpec).to respond_to(:parsable?)
  end
end

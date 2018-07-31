# frozen_string_literal: true

require_relative "lt_xcodebuild"
require_relative "options/lt_test_options"
require_relative "../helpers/fastlane_bugfixes"
require_relative "../helpers/action_helper"
require_relative "../helpers/junit_helper"
require_relative "../helpers/result_bundle_helper"

module Fastlane
  module Actions
    # Action that build and immeditely run tests of an xcodebuild targets.
    class LtBuildAndTestAction < Action
      def self.description
        "Builds and tests xcodebuild targets"
      end

      def self.details
        "Builds an xcodebuild target with the provided options, while writing raw log to file. " \
        "Generates junit and html reports that contains the results of the test."
      end

      def self.available_options
        [
          LtXcodebuildOptions.project_option,
          LtXcodebuildOptions.workspace_option,
          LtXcodebuildOptions.scheme_option,
          LtXcodebuildOptions.configuration_option,
          LtXcodebuildOptions.destination_option,
          LtXcodebuildOptions.derived_data_path_option,
          LtXcodebuildOptions.result_bundle_path_option,
          LtXcodebuildOptions.other_flags_option,
          LtXcodebuildOptions.enable_thread_sanitizer_option,
          LtXcodebuildOptions.enable_address_sanitizer_option,
          LtXcodebuildOptions.enable_undefined_behavior_sanitizer_option,
          LtXcodebuildOptions.raw_logfile_path_option,
          LtXcodebuildOptions.treat_warnings_as_errors_option(default_value: true),
          LtXcodebuildOptions.ccache_option
        ] + LtTestOptions.available_options
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def self.run(params)
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        Helpers.kill_simulators

        exit_code = other_action.lt_xcodebuild(
          project: params[:project],
          workspace: params[:workspace],
          scheme: params[:scheme],
          configuration: params[:configuration],
          destination: params[:destination],
          other_flags: params[:other_flags],
          derived_data_path: params[:derived_data_path],
          result_bundle_path: params[:test_result_path],
          enable_thread_sanitizer: params[:enable_thread_sanitizer],
          enable_address_sanitizer: params[:enable_address_sanitizer],
          enable_undefined_behavior_sanitizer: params[:enable_undefined_behavior_sanitizer],
          raw_logfile_path: params[:raw_logfile_path],
          treat_warnings_as_errors: params[:treat_warnings_as_errors],
          ccache: params[:ccache],
          actions: "clean test"
        )

        Helpers::ResultBundle.result_bundle_to_junit(params[:test_result_path],
                                                     params[:junit_report_path])

        UI.message("Parsing test results")
        _total_test_cases, failed_test_cases =
          Helpers::Junit.parse_junit_tests(params[:junit_report_path])

        if failed_test_cases.count.positive?
          UI.error("Failed test cases:")
          failed_test_cases.each { |test_case| UI.error("\t#{test_case}") }
          UI.test_failure!("Tests failed")
        end

        UI.build_failure!("Build failed, see logs for more details") if exit_code.nonzero?

        UI.success("Build and test completed successfully")
      end
    end
  end
end

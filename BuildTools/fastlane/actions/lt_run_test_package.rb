# frozen_string_literal: true

require_relative "lt_xcodebuild"
require_relative "options/lt_test_options"
require_relative "options/lt_test_package_options"
require_relative "../helpers/fastlane_bugfixes"
require_relative "../helpers/action_helper"
require_relative "../helpers/junit_helper"

module Fastlane
  module Actions
    # Action that runs the tests from a given test package that contains .xctestrun file.
    class LtRunTestPackageAction < Action
      BUILD_DIR_DERIVED_DATA_REGEX = /BUILD_DIR = (.*)\n/

      def self.description
        "Runs tests from a test package"
      end

      def self.details
        "Runs a given test package and generates junit and html reports that contains the " \
        "results of the test"
      end

      def self.available_options
        [
          LtXcodebuildOptions.destination_option,
          LtXcodebuildOptions.derived_data_path_option,
          LtXcodebuildOptions.result_bundle_path_option,
          LtXcodebuildOptions.other_flags_option,
          LtXcodebuildOptions.raw_logfile_path_option
        ] + LtTestOptions.available_options + LtTestPackageOptions.available_options
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def self.run(params)
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
        test_package_path = File.absolute_path(params[:package_path])
        xctestrun_files = Dir.glob(File.join(test_package_path, "*.xctestrun"))
        if xctestrun_files.count != 1
          UI.build_failure!("Expected a single 'xctestrun' file to be generated, but got " \
                            "#{xctestrun_files}")
        end

        Helpers.kill_simulators

        exit_code = other_action.lt_xcodebuild(
          xctestrun: xctestrun_files.first,
          ccache: false,
          destination: params[:destination],
          derived_data_path: params[:derived_data_path],
          other_flags: params[:other_flags],
          raw_logfile_path: params[:raw_logfile_path],
          result_bundle_path: params[:test_result_path],
          actions: "test-without-building"
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

        UI.test_failure!("Test failed, see logs for more details") if exit_code.nonzero?

        UI.success("Testing completed successfully")
      end
    end
  end
end

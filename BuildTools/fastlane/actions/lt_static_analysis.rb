# frozen_string_literal: true

require_relative "lt_xcodebuild"
require_relative "../helpers/static_analysis_report_generator"
require_relative "../helpers/action_helper"

module Fastlane
  module Actions
    # Action that runs static analysis on xcodebuild targets.
    class LtStaticAnalysisAction < Action
      STATIC_ANALYSIS_REPORTS_DIR_PATH = "build/static_analysis"

      def self.description
        "Runs the default static analyzer"
      end

      def self.details
        "Run the analysis action on a given xcodebuild target and generate reports containing the" \
        "results of the analysis"
      end

      # rubocop:disable Metrics/MethodLength
      def self.available_options
        # rubocop:enable Metrics/MethodLength
        [
          FastlaneCore::ConfigItem.new(
            key: :html_report_path,
            env_name: "LT_STATIC_ANALYSIS_HTML_RESULT_PATH",
            description: "Path to a directory where the HTML report will be generated in",
            type: String,
            optional: true,
            default_value: "output/test_results/tests.html"
          ),
          LtXcodebuildOptions.project_option,
          LtXcodebuildOptions.workspace_option,
          LtXcodebuildOptions.scheme_option,
          LtXcodebuildOptions.configuration_option,
          LtXcodebuildOptions.destination_option,
          LtXcodebuildOptions.sdk_option,
          LtXcodebuildOptions.arch_option,
          LtXcodebuildOptions.derived_data_path_option,
          LtXcodebuildOptions.other_flags_option,
          LtXcodebuildOptions.raw_logfile_path_option,
          LtXcodebuildOptions.treat_warnings_as_errors_option(default_value: false),
          LtXcodebuildOptions.ccache_option(default_value: false)
        ] + LtTestOptions.available_options
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def self.run(params)
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
        FileUtils.rm_rf(STATIC_ANALYSIS_REPORTS_DIR_PATH)

        analyzer_output_dir = File.absolute_path(File.join(Dir.pwd,
                                                           STATIC_ANALYSIS_REPORTS_DIR_PATH))
        clang_analyzer_args =
          "CLANG_ANALYZER_OUTPUT=html CLANG_ANALYZER_OUTPUT_DIR=\"#{analyzer_output_dir}\""

        exit_code = other_action.lt_xcodebuild(
          project: params[:project],
          workspace: params[:workspace],
          scheme: params[:scheme],
          configuration: params[:configuration],
          destination: params[:destination],
          sdk: params[:sdk],
          arch: params[:arch],
          derived_data_path: params[:derived_data_path],
          result_bundle_path: params[:test_result_path],
          other_flags: params[:other_flags].to_s + clang_analyzer_args,
          raw_logfile_path: params[:raw_logfile_path],
          treat_warnings_as_errors: params[:treat_warnings_as_errors],
          ccache: params[:ccache],
          actions: "clean analyze"
        )

        UI.build_failure!("Build failed, see logs for more details") unless exit_code.zero?

        UI.message("Parsing static analysis results")
        issue_count = StaticAnalysisReportGenerator.new.generate_report(analyzer_output_dir,
                                                                        params[:junit_report_path],
                                                                        params[:html_report_path])
        if issue_count.positive?
          _, failed_test_cases = Helpers::Junit.parse_junit_tests(params[:junit_report_path])
          UI.error("Static analysis issues:")
          failed_test_cases.each { |test_case| UI.error("\t#{test_case}") }
          UI.test_failure!("#{failed_test_cases.count} issue(s) found")
        end

        UI.success("Static analysis completed successfully")
      end
    end
  end
end

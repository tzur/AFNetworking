# frozen_string_literal: true

module Fastlane
  module Actions
    # Options used to specify the parameters of test actions.
    class LtTestOptions
      def self.test_result_path_option
        FastlaneCore::ConfigItem.new(
          key: :test_result_path,
          env_name: "LT_TEST_TEST_RESULT_PATH",
          description: "Path to a directory that will contain the result of the test. Results " \
                       "include Junit report, test crash dumps, and screenshots collected",
          type: String,
          optional: true,
          default_value: "output/test_results"
        )
      end

      def self.junit_report_path_option
        FastlaneCore::ConfigItem.new(
          key: :junit_report_path,
          env_name: "LT_TEST_JUNIT_RESULT_PATH",
          description: "Path where the junit report will be generated in",
          type: String,
          optional: true,
          default_value: "output/test_results/junit.xml"
        )
      end

      def self.available_options
        methods.select { |method| method.match?(/option$/) }
               .map { |method| send(method) }
      end
    end
  end
end

# frozen_string_literal: true

module Fastlane
  module Actions
    module Helpers
      BASE_DIR_ABSOLUTE_PATH = File.expand_path("..", File.dirname(__FILE__))

      class Junit
        # Returns the total tests ran and an Array containing the list of failed test cases.
        #
        # @param junit_file_path (String): Path to a junit xml file.
        def self.parse_junit_tests(junit_file_path)
          require "rexml/document"

          total_tests_count = 0
          failed_test_cases = []

          return [total_tests_count, failed_test_cases] unless File.file?(junit_file_path)

          File.open(junit_file_path) do |file|
            doc = REXML::Document.new(file)
            total_tests_count = doc.root["tests"].to_i

            failed_test_cases = doc.root.elements.map do |test_suite|
              test_suite.elements.reject { |test_case| test_case.elements.empty? }
                        .map do |test_case|
                "#{test_case['classname']} - #{test_case['name']}"
              end
            end.flatten.uniq
          end
          [total_tests_count, failed_test_cases]
        end
      end

      def self.script_path(filename = "")
        File.join(BASE_DIR_ABSOLUTE_PATH, "scripts", filename)
      end

      def self.resource_path(filename = "")
        File.join(BASE_DIR_ABSOLUTE_PATH, "resources", filename)
      end
    end
  end
end

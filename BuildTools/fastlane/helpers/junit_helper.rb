# frozen_string_literal: true

require "rexml/document"

module Fastlane
  module Actions
    module Helpers
      class Junit
        # Returns the total tests ran and an Array containing the list of failed test cases.
        #
        # @param junit_file_path (String): Path to a junit xml file.
        def self.parse_junit_tests(junit_file_path)
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

        class TestSuite
          attr_reader :name, :test_cases

          def initialize(name, test_cases)
            @name, @test_cases = name, test_cases
          end
        end

        class TestCase
          attr_reader :name, :successful, :duration, :failure_message, :stack_trace
          alias_method :successful?, :successful

          def self.successful_test_case(name, duration)
            self.new(name, duration)
          end

          def self.failed_test_case(name, duration, failure_message, stack_trace)
            self.new(name, duration, failure_message, stack_trace)
          end

        private
          def initialize(name, duration, failure_message = nil, stack_trace = nil)
            @name, @duration, @failure_message, @stack_trace =
                name, duration, failure_message, stack_trace
            @successful = failure_message.nil?
          end
        end

        def self.write_xml_document(document, file_path)
          require "rexml/formatters/pretty"

          formatter = REXML::Formatters::Pretty.new(2)
          formatter.compact = true
          File.open(file_path, "w") { |file| formatter.write(document, file) }
        end

        def self.junit_report_from_test_suites(test_suites)
          test_cases = test_suites.map(&:test_cases).flatten

          total_test_cases = test_cases.count
          total_failed_test_cases = test_cases.reject(&:successful?).count

          document = REXML::Document.new
          document << REXML::XMLDecl.new("1.0", "UTF-8")
          suites = document.add_element("testsuites", "name" => "All tests",
                                                      "tests" => total_test_cases,
                                                      "failures" => total_failed_test_cases)

          test_suites.each do |test_suite|
            suite = suites.add_element("testsuite",
                                       "name" => test_suite.name,
                                       "tests" => test_suite.test_cases.count,
                                       "failures" => test_suite.test_cases.reject(&:successful?).count)

            test_suite.test_cases.each do |test_case|
              testcase = suite.add_element("testcase", "classname" => test_suite.name,
                                                       "name" => test_case.name)
              unless test_case.successful?
                failure = testcase.add_element("failure", "message" => test_case.failure_message)
                failure.text = test_case.stack_trace
              end
            end
          end

          document
        end
      end
    end
  end
end

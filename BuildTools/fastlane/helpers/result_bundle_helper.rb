# frozen_string_literal: true

require "plist"
require_relative "junit_helper"

module Fastlane
  module Actions
    module Helpers
      # Contains methods to help analyze the data in xcodebuild's result bundles.
      class ResultBundle
        SUPPORTED_FORMAT_VERSIONS = ["1.2"].freeze

        def self.result_bundle_to_junit(result_bundle_path, junit_file_path)
          test_summaries = Dir.glob(File.join(result_bundle_path, "*",
                                              "action_TestSummaries.plist"))
          all_test_suites = test_summaries.map do |test_summaries_file_path|
            plist = File.open(test_summaries_file_path) { |f| Plist.parse_xml(f) }

            verify_file_format_version(plist)
            test_suffix = device_description(plist)

            test_summary_groups = extract_test_summary_group(plist)
            test_summary_groups.map do |test_summary_group|
              test_summary_group_to_junit_test_suite(test_summary_group, test_suffix)
            end
          end.flatten

          junit_document = Junit.junit_report_from_test_suites(all_test_suites)
          Junit.write_xml_document(junit_document, junit_file_path)
        end

        private_class_method
        def self.extract_test_summary_group(plist)
          # Flatten the test hierarchy so only two levels will be left - classes and test cases.
          # Each spec file is represented by a "ActionTestSummaryGroup" object and each test case
          # is represented by a "ActionTestSummary" object.
          # The resources directory contains a sample plist file for each of the supported formats.
          action_testable_summaries = plist["TestableSummaries"]
          verify_test_object_class(action_testable_summaries[0], "IDESchemeActionTestableSummary")

          action_test_summary_groups = action_testable_summaries.flat_map { |e| e["Tests"] }
          verify_test_object_class(action_test_summary_groups[0], "IDESchemeActionTestSummaryGroup")

          sub_action_test_summary_groups = action_test_summary_groups.flat_map { |e| e["Subtests"] }
          verify_test_object_class(sub_action_test_summary_groups[0], "IDESchemeActionTestSummaryGroup")

          sub_action_test_summary_groups = sub_action_test_summary_groups.flat_map { |e| e["Subtests"] }
          verify_test_object_class(sub_action_test_summary_groups[0], "IDESchemeActionTestSummaryGroup")

          action_test_summaries = sub_action_test_summary_groups[0]["Subtests"]
          verify_test_object_class(action_test_summaries[0], "IDESchemeActionTestSummary")

          sub_action_test_summary_groups
        end

        private_class_method
        def self.verify_test_object_class(test_object, test_object_class)
          # Verifies that the given test_object is of class test_object_class.
          object_class = test_object["TestObjectClass"]
          unless object_class == test_object_class
            UI.abort_with_message!("Expecting #{test_object_class} object, but got ${object_class}")
          end       
        end

        private_class_method
        def self.test_summary_group_to_junit_test_suite(test_summary_group, test_suffix)
          # Converts an array of TestSummaryGroup objects to and array of Junit::TestSuite objects.
          test_cases = test_summary_group["Subtests"].map do |test_summary|
            case_name = test_summary["TestName"]
            duration = test_summary["Duration"]
            successful = test_summary["TestStatus"] == "Success"
            next Junit::TestCase.successful_test_case(case_name, duration) if successful

            next test_summary["FailureSummaries"].map do |test_failure|
              relative_file_path = Pathname.new(test_failure["FileName"])
              stack_trace = [relative_file_path, test_failure["LineNumber"]].join(":")
              Junit::TestCase.failed_test_case(case_name, duration, test_failure["Message"],
                                               stack_trace)
            end
          end.flatten

          suite_name = [test_summary_group["TestName"], test_suffix].join(" - ")
          Junit::TestSuite.new(suite_name, test_cases)
        end

        private_class_method
        def self.verify_file_format_version(plist)
          format_version = plist["FormatVersion"]
          return if SUPPORTED_FORMAT_VERSIONS.include?(format_version)
          UI.abort_with_message!("Result bundle format version #{format_version} is " \
              "unsupported. Supported versions include #{SUPPORTED_FORMAT_VERSIONS}")
        end

        private_class_method
        def self.device_description(plist)
          target_device = plist["RunDestination"]["TargetDevice"]
          device_model = target_device["ModelName"] # iPhone 8
          os = target_device["OperatingSystemVersionWithBuildNumber"] # 11.4 (15F79)
          platform = target_device["Platform"]["Name"] # iOS Simulator / iOS

          # Platform for iOS simulator is "iOS Simulator", but for device it's just "iOS". Add
          # "Device" if the platform is not a simulator.
          platform << " Device" unless platform.include?("Simulator")

          [device_model, platform, os].join(" - ")
        end
      end
    end
  end
end

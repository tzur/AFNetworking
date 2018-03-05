# frozen_string_literal: true

module FastlaneCore
  # Configuration item that report in xcpretty.
  class XcprettyConfigItem < ConfigItem
    attr_accessor :xcpretty_report

    def initialize(xcpretty_report:, **args)
      super(**args)
      @xcpretty_report = xcpretty_report
    end
  end
end

module Fastlane
  module Actions
    # Options for the LtXcpretty action.
    class LtXcprettyOptions
      def self.junit_report_path_option
        FastlaneCore::XcprettyConfigItem.new(
          key: :junit_report_path,
          env_name: "LT_XCPRETTY_JUNIT_REPORT_PATH",
          description: "Path to the junit report to create from the raw xcodebuild log",
          type: String,
          xcpretty_report: "junit",
          optional: true,
          default_value: "output/reports/junit.xml"
        )
      end

      def self.html_junit_report_path_option
        FastlaneCore::XcprettyConfigItem.new(
          key: :html_report_path,
          env_name: "LT_XCPRETTY_HTML_REPORT_PATH",
          description: "Path to the html report to create from the raw xcodebuild log",
          type: String,
          xcpretty_report: "html",
          optional: true,
          default_value: "output/reports/tests.html"
        )
      end

      def self.available_options
        methods.select { |method| method.match?(/option$/) }
               .map { |method| send(method) }
      end
    end
  end
end

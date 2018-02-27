# frozen_string_literal: true

require_relative "../helpers/executor"
require_relative "../helpers/fastlane_bugfixes"
require_relative "options/lt_xcpretty_options"

module Fastlane
  module Actions
    # Action that generates xcpretty reports from xcodebuild logs.
    class LtXcprettyAction < Action
      def self.description
        "Generates xcpretty reports from raw xcodebuild log"
      end

      def self.available_options
        [LtXcodebuildOptions.raw_logfile_path_option] + LtXcprettyOptions.available_options
      end

      def self.run(params)
        raw_logfile_path = params[:raw_logfile_path]
        xcpretty_flags = generate_xcpretty_flags(params)
        command = "set -o pipefail && cat #{raw_logfile_path} | " \
                  "xcpretty #{xcpretty_flags} > /dev/null"
        exit_code, = Executor.execute(command)
        UI.abort_with_message!("xcpretty failed. Exit code #{exit_code}") if exit_code != 0
      end

      def self.generate_xcpretty_flags(params)
        params.available_options
              .select { |option| option.is_a?(FastlaneCore::XcprettyConfigItem) }
              .map { |option| [option.key, params[option.key], option.xcpretty_report] }
              .reject { |_, value, _| value.nil? }
              .map do |_, value, report|
          "--report #{report} --output #{value}"
        end.compact.join(" ")
      end
    end
  end
end

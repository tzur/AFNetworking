# frozen_string_literal: true

module Fastlane
  module Actions
    # Options for the actions using test packages.
    class LtTestPackageOptions
      def self.package_path_option
        FastlaneCore::ConfigItem.new(
          key: :package_path,
          env_name: "LT_XCODEBUILD_TEST_PACKAGE_PATH",
          description: "Path to a directory containing or will contain test package",
          type: String,
          default_value: "output/test_package"
        )
      end

      def self.available_options
        methods.select { |method| method.match?(/option$/) }
               .map { |method| send(method) }
      end
    end
  end
end

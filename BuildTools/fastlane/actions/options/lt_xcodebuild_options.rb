# frozen_string_literal: true

require "pathname"

module FastlaneCore
  # Configuration item that defines a flag passed to 'xcodebuild'.
  class XcodebuildConfigItem < ConfigItem
    attr_accessor :xcodebuild_flag

    def initialize(xcodebuild_flag:, **args)
      super(**args)
      @xcodebuild_flag = xcodebuild_flag
    end
  end
end

module Fastlane
  module Actions
    # Options for the LtXcodebuild action.

    # rubocop:disable Metrics/ClassLength
    class LtXcodebuildOptions
      # rubocop:enable Metrics/ClassLength

      # All build actions supported by this action.
      BUILD_ACTIONS = [
        "build",
        "build-for-testing",
        "analyze",
        "archive",
        "test",
        "test-without-building",
        "install-src",
        "install",
        "clean"
      ].freeze

      # All SDKs supported by the action.
      SDKS = [
        "iphoneos",
        "iphonesimulator"
      ].freeze

      # All archs supported by this action.
      ARCHS = [
        "arm64",
        "x86_64",
        "armv7",
        "armv7s",
        "i386"
      ].freeze

      def self.actions_option
        FastlaneCore::ConfigItem.new(
          key: :actions,
          env_name: "LT_XCODEBUILD_BUILD_ACTIONS",
          description: "Build actions to use, separated by space. e.g. \"clean build test\"",
          type: String,
          verify_block: proc do |value|
            value.split.each do |action|
              UI.user_error!("Unknown build action #{action}") unless BUILD_ACTIONS.include?(action)
            end
          end
        )
      end

      def self.project_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :project,
          env_name: "LT_XCODEBUILD_PROJECT",
          description: "Path to .xcodeproj file to build",
          xcodebuild_flag: "-project",
          type: String,
          verify_block: proc do |value|
            UI.user_error!("Project file not found at path '#{value}'") unless File.exist?(value)
            UI.user_error!("Invalid project file") unless File.directory?(value)
            unless value.end_with?(".xcodeproj")
              UI.user_error!("Project file is not a project, must end with .xcodeproj")
            end
          end,
          conflicting_options: [:workspace],
          optional: true
        )
      end

      def self.workspace_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :workspace,
          env_name: "LT_XCODEBUILD_WORKSPACE",
          description: "Path to .xcworkspace file to build",
          xcodebuild_flag: "-workspace",
          type: String,
          verify_block: proc do |value|
            unless File.exist?(value)
              UI.user_error!("Workspace file not found at path '#{abs_path}'")
            end
            UI.user_error!("Invalid workspace file") unless File.directory?(value)
            unless value.end_with?(".xcworkspace")
              UI.user_error!("Workspace file is not a workspace, must end with .xcworkspace")
            end
          end,
          conflicting_options: [:project],
          optional: true
        )
      end

      def self.scheme_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :scheme,
          env_name: "LT_XCODEBUILD_SCHEME",
          description: "Scheme in project or workspace to build",
          xcodebuild_flag: "-scheme",
          type: String,
          optional: true
        )
      end

      def self.configuration_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :configuration,
          env_name: "LT_XCODEBUILD_CONFIGURATION",
          description: "Build configuration to use, defaults to Debug",
          xcodebuild_flag: "-configuration",
          type: String,
          optional: true,
          default_value: "Debug"
        )
      end

      def self.destination_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :destination,
          env_name: "LT_XCODEBUILD_DESTINATION",
          description: "Destination string to build or test on. For example: " \
                       "\"platform=iOS Simulator,name=iPhone 6s Plus,OS=latest\"",
          xcodebuild_flag: "-destination",
          type: String,
          conflicting_options: [:sdk, :arhcs],
          optional: true
        )
      end

      def self.sdk_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :sdk,
          env_name: "LT_XCODEBUILD_SDK",
          description: "SDK to use when building. Must be one of #{SDKS}. Does not have a " \
                       "default value, but xcodebuild uses \"iphoneos\" if not set and " \
                       "\"destination\" is not used. May lead to building for multiple " \
                       "architechtures unless \"arhcs\" is used",
          xcodebuild_flag: "-sdk",
          type: String,
          verify_block: proc do |value|
            unless SDKS.include?(value)
              UI.user_error!("Unknown SDK #{value}, must be on of #{SDKS}")
            end
          end,
          conflicting_options: [:destination],
          optional: true
        )
      end

      def self.arch_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :arch,
          env_name: "LT_XCODEBUILD_ARCH",
          description: "Array of architechtures to build. Must be one of #{ARCHS}. This option " \
                       "can be used further specify the architechtures to build when using \"sdk\"",
          xcodebuild_flag: "-arch",
          type: Array,
          verify_block: proc do |values|
            values.each do |arch|
              unless ARCHS.include?(arch)
                UI.user_error!("Unknown architechture #{arch}, must be on of #{ARCHS}")
              end
            end
          end,
          conflicting_options: [:destination],
          optional: true
        )
      end

      def self.xctestrun_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :xctestrun,
          env_name: "LT_XCODEBUILD_XCTESTRUN",
          description: "Path to xctestrun inside derived data folder",
          xcodebuild_flag: "-xctestrun",
          type: String,
          verify_block: proc do |value|
            UI.user_error!("Xctestrun file not found at path '#{value}'") unless File.exist?(value)
            UI.user_error!("Xctestrun file invalid") unless File.file?(value)
            unless value.end_with?(".xctestrun")
              UI.user_error!("Xctestrun file must end with .xctestrun")
            end
          end,
          conflicting_options: [:project, :workspace, :scheme],
          optional: true
        )
      end

      def self.derived_data_path_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :derived_data_path,
          env_name: "LT_XCODEBUILD_DERIVED_DATA_PATH",
          description: "Path pointing to the derived data directory",
          xcodebuild_flag: "-derivedDataPath",
          type: String,
          optional: true
        )
      end

      def self.result_bundle_path_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :result_bundle_path,
          env_name: "LT_XCODEBUILD_RESULT_BUNDLE_PATH",
          description: "Path to generate result bundle path in",
          xcodebuild_flag: "-resultBundlePath",
          verify_block: proc do |value|
            if Pathname.new(value).absolute? || value.include?("..")
              UI.user_error!("Result bundle path must be relative and not escape current directory")
            end
          end,
          type: String,
          optional: true
        )
      end

      def self.other_flags_option
        FastlaneCore::ConfigItem.new(
          key: :other_flags,
          env_name: "LT_XCODEBUILD_OTHER_FLAGS",
          description: "Additional flags to pass to xcodebuild",
          type: String,
          optional: true
        )
      end

      def self.enable_thread_sanitizer_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :enable_thread_sanitizer,
          env_name: "LT_XCODEBUILD_THREAD_SANITIZER",
          description: "Whether to enable thread sanitizer or not",
          xcodebuild_flag: "-enableThreadSanitizer",
          optional: true,
          type: Boolean
        )
      end

      def self.enable_address_sanitizer_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :enable_address_sanitizer,
          env_name: "LT_XCODEBUILD_ADDRESS_SANITIZER",
          description: "Whether to enable address sanitizer or not",
          xcodebuild_flag: "-enableAddressSanitizer",
          optional: true,
          type: Boolean
        )
      end

      def self.enable_undefined_behavior_sanitizer_option
        FastlaneCore::XcodebuildConfigItem.new(
          key: :enable_undefined_behavior_sanitizer,
          env_name: "LT_XCODEBUILD_UNDEFIEND_BEHAVIOR_SANITIZER",
          description: "Whether to enable undefined behavior sanitizer or not",
          xcodebuild_flag: "-enableUndefinedBehaviorSanitizer",
          optional: true,
          type: Boolean
        )
      end

      def self.raw_logfile_path_option
        FastlaneCore::ConfigItem.new(
          key: :raw_logfile_path,
          env_name: "LT_XCODEBUILD_RAW_LOG_PATH",
          description: "Path to the raw xcodebuild log file",
          type: String,
          optional: true,
          default_value: "output/logs/xcodebuild.log"
        )
      end

      def self.treat_warnings_as_errors_option(default_value: true)
        FastlaneCore::ConfigItem.new(
          key: :treat_warnings_as_errors,
          env_name: "LT_XCODEBUILD_TREAT_WARNINGS_AS_ERRORS",
          description: "Whether the TREAT_WARNINGS_AS_ERRORS flag is set to YES. Defaults to" \
                       "true, relevant only to build",
          optional: true,
          type: Boolean,
          default_value: default_value
        )
      end

      def self.ccache_option(default_value: true)
        FastlaneCore::ConfigItem.new(
          key: :ccache,
          env_name: "LT_XCODEBUILD_CCACHE",
          description: "Whether of not to enable ccache when building",
          optional: true,
          type: Boolean,
          default_value: default_value
        )
      end

      def self.available_options
        methods.select { |method| method.match?(/option$/) }
               .map { |method| send(method) }
      end
    end
  end
end

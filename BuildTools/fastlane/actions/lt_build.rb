# frozen_string_literal: true

require_relative "lt_xcodebuild"

module Fastlane
  module Actions
    # Action that builds xcodebuild targets.
    class LtBuildAction < Action
      def self.description
        "Builds xcodebuild targets"
      end

      def self.details
        "Builds an xcodebuild target with the provided options, while writing raw log to file. "
      end

      # rubocop:disable Metrics/MethodLength
      def self.available_options
        # rubocop:enable Metrics/MethodLength
        [
          FastlaneCore::ConfigItem.new(
            key: :with_tests,
            env_name: "LT_XCODEBUILD_BUILD_WITH_TESTS",
            description: "Whether of not to build the test target of the given scheme",
            type: Boolean,
            default_value: false
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
          LtXcodebuildOptions.treat_warnings_as_errors_option(default_value: true),
          LtXcodebuildOptions.ccache_option(default_value: true)
        ]
      end

      def self.run(params)
        build_action = params[:with_tests] ? "build-for-testing" : "build"

        exit_code = other_action.lt_xcodebuild(
          project: params[:project],
          workspace: params[:workspace],
          scheme: params[:scheme],
          configuration: params[:configuration],
          destination: params[:destination],
          sdk: params[:sdk],
          arch: params[:arch],
          derived_data_path: params[:derived_data_path],
          other_flags: params[:other_flags],
          raw_logfile_path: params[:raw_logfile_path],
          treat_warnings_as_errors: params[:treat_warnings_as_errors],
          ccache: params[:ccache],
          actions: "clean #{build_action}"
        )

        UI.build_failure!("Build failed, see logs for more details") unless exit_code.zero?
        UI.success("Build completed successfully")
      end
    end
  end
end

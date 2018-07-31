# frozen_string_literal: true

require_relative "lt_xcodebuild"
require_relative "options/lt_test_package_options"
require_relative "../helpers/fastlane_bugfixes"
require_relative "../helpers/action_helper"

module Fastlane
  module Actions
    # Action that build a given xcodebuild target, along with the test targets for that target.
    # The output is a test package with that includes (among other files) an .xctestrun file that
    # can be used to later test the package.
    class LtBuildTestPackageAction < Action
      def self.description
        "Builds xcodebuild targets for testing"
      end

      def self.details
        "Builds an xcodebuild target for testing with the provided options, the package can be " \
        "later tested"
      end

      def self.available_options
        [
          LtXcodebuildOptions.project_option,
          LtXcodebuildOptions.workspace_option,
          LtXcodebuildOptions.scheme_option,
          LtXcodebuildOptions.configuration_option,
          LtXcodebuildOptions.destination_option,
          LtXcodebuildOptions.sdk_option,
          LtXcodebuildOptions.arch_option,
          LtXcodebuildOptions.derived_data_path_option,
          LtXcodebuildOptions.other_flags_option,
          LtXcodebuildOptions.enable_thread_sanitizer_option,
          LtXcodebuildOptions.enable_address_sanitizer_option,
          LtXcodebuildOptions.enable_undefined_behavior_sanitizer_option,
          LtXcodebuildOptions.raw_logfile_path_option,
          LtXcodebuildOptions.treat_warnings_as_errors_option(default_value: true),
          LtXcodebuildOptions.ccache_option
        ] + LtTestPackageOptions.available_options
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def self.run(params)
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        test_package_path = params[:package_path]
        test_package_flags = "-IDEBuildLocationStyle=Custom " \
                             "-IDECustomBuildLocationType=Absolute " \
                             "-IDECustomBuildProductsPath=\"$PWD/#{test_package_path}\""

        other_flags = [params[:other_flags], test_package_flags].join(" ")

        exit_code = other_action.lt_xcodebuild(
          project: params[:project],
          workspace: params[:workspace],
          scheme: params[:scheme],
          configuration: params[:configuration],
          destination: params[:destination],
          sdk: params[:sdk],
          arch: params[:arch],
          derived_data_path: params[:derived_data_path],
          enable_thread_sanitizer: params[:enable_thread_sanitizer],
          enable_address_sanitizer: params[:enable_address_sanitizer],
          enable_undefined_behavior_sanitizer: params[:enable_undefined_behavior_sanitizer],
          raw_logfile_path: params[:raw_logfile_path],
          treat_warnings_as_errors: params[:treat_warnings_as_errors],
          ccache: params[:ccache],
          other_flags: other_flags,
          actions: "clean build-for-testing"
        )

        UI.build_failure!("Build failed, see logs for more details") if exit_code.nonzero?

        xctestrun_files = Dir.glob(File.join(test_package_path, "*.xctestrun"))
        if xctestrun_files.count != 1
          UI.build_failure!("Expected a single 'xctestrun' file to be generated, but got " \
                           "#{xctestrun_files}")
        end

        # The products directory contains all the .a files needed for linking, but are not needed
        # to run tests so they can be deleted.
        Dir.glob(File.join(test_package_path, "**", "*.a")).each { |file| File.delete(file) }

        UI.success("Build test package completed successfully")
      end
    end
  end
end

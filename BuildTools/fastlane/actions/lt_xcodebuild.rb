# frozen_string_literal: true

require_relative "../helpers/executor"
require_relative "../helpers/xcodebuild_errors"
require_relative "../helpers/fastlane_bugfixes"
require_relative "options/lt_xcodebuild_options"

require "fileutils"

module Fastlane
  module Actions
    # Action that wraps most of xcodebuild flags.
    class LtXcodebuildAction < Action
      MAX_ATTEMPTS = 3

      def self.description
        "Executes 'xcodebuild' with the given options"
      end

      def self.details
        "Executes xcodebuild with the given options, while saving the raw log to file, and using " \
        "xcpretty to show the log. Supports execution with ccache. see 'man xcodebuild' for a " \
        "full list of 'xcodebuid' flags"
      end

      def self.available_options
        LtXcodebuildOptions.available_options
      end

      def self.return_value
        "The exit code of the xcodebuild command"
      end

      def self.run(params)
        unless params[:project] || params[:workspace] || params[:xctestrun]
          UI.user_error!("Either 'project', 'workspace' or 'xctestrun' must be provided")
        end

        raw_logfile_path = params[:raw_logfile_path]
        FileUtils.mkdir_p(File.dirname(raw_logfile_path))

        xcodebuild_flags = generate_xcodebuild_flags(params)
        xcpretty_flags = "--simple --color"
        command = "set -o pipefail && xcodebuild #{xcodebuild_flags} | " \
                  "tee \"#{raw_logfile_path}\" | " \
                  "xcpretty #{xcpretty_flags}"

        attempts_left = MAX_ATTEMPTS
        while attempts_left > 0
          attempts_left -= 1

          result_bundle_path = params[:result_bundle_path]
          if result_bundle_path && File.exist?(result_bundle_path)
            UI.message("The result bundle directory already exists, deleting it.")
            FileUtils.remove_dir(result_bundle_path, force=true)
          end

          exit_code, _, stderr = Executor.execute(command)
          if exit_code.zero?
            UI.success("xcodebuild completed successfully")
            break
          else
            XcodebuildErrors.filter_errors(stderr).each { |line| UI.error(line) }
            UI.error("xcodebuild failed. Exit code #{exit_code}")
            unless XcodebuildErrors.should_retry_xcodebuild?(stderr)
              break
            end

            if attempts_left > 0
              UI.important("An error due to a bug in the simulator has been detected. retrying " \
                           "xcodebuild again. #{attempts_left} attempts left")
            else
              UI.error("xcodebuild failed too many times (#{MAX_ATTEMPTS})")
            end
          end          
        end

        exit_code
      end

      def self.scripts_dir_path
        absolute_scripts_dir_path = File.join(File.dirname(__FILE__), "..", "scripts")
        Pathname.new(absolute_scripts_dir_path).relative_path_from(Pathname.new(Dir.pwd))
      end

      def self.ccache_flags
        # The path to ccache scripts is kept relative and "$PWD" is left for the shell to unpack
        # because then the command (which is printed to screen) is kept portable and can be copied
        # to another workspace and run there.
        relative_scripts_dir_path = scripts_dir_path
        c_ccache_script_path = File.join(relative_scripts_dir_path, "ccache-clang.sh")
        cxx_ccache_script_path = File.join(relative_scripts_dir_path, "ccache-clang++.sh")

        unless File.file?(c_ccache_script_path) && File.file?(cxx_ccache_script_path)
          UI.abort_with_message!("Missing ccache scripts in #{relative_scripts_dir_path}")
        end

        "CC=\"$PWD/#{c_ccache_script_path}\" " \
        "CXX=\"$PWD/#{cxx_ccache_script_path}\" " \
        "GCC_PRECOMPILE_PREFIX_HEADER=NO " \
        "CLANG_ENABLE_MODULES=NO"
      end

      def self.generate_xcodebuild_flags(params)
        flags = params.available_options
                      .select { |option| option.is_a?(FastlaneCore::XcodebuildConfigItem) }
                      .map { |option| [option.key, params[option.key], option.xcodebuild_flag] }
                      .reject { |_, value, _| value.nil? }
                      .map do |key, value, flag|
          case value
          when String
            "#{flag} \"#{value}\""
          when Array
            value.map { |val| "#{flag} \"#{val}\"" }.join(" ")
          when TrueClass, FalseClass
            "#{flag} #{value ? 'YES' : 'NO'}"
          else
            UI.crash!("Unknown type #{value.class} for option #{key}")
          end
        end.compact.join(" ")

        unless params[:treat_warnings_as_errors].nil?
          flags << " TREAT_WARNINGS_AS_ERRORS=#{params[:treat_warnings_as_errors] ? 'YES' : 'NO'}"
        end

        if params[:enable_undefined_behavior_sanitizer]
          if params[:other_flags]
            UI.user_error!("Undefined behavior sanitizer cannot be used with 'other_flags'")
          end
          flags << " OTHER_CFLAGS=\"${inherited} -fno-sanitize-recover=all\""
        end

        flags << " " << params[:other_flags] if params[:other_flags]
        flags << " " << ccache_flags if params[:ccache]

        "#{flags} #{params[:actions]}"
      end
    end
  end
end

# frozen_string_literal: true

module Fastlane
  module Actions
    module SharedValues
      ADHOC_IPA_OUTPUT_PATH = :ADHOC_IPA_OUTPUT_PATH
      APPSTORE_IPA_OUTPUT_PATH = :APPSTORE_IPA_OUTPUT_PATH
    end

    # Action that archives, signs and exports xcodebuild targets.
    class LtDistributionAction < Action
      BUNDLE_IDENTIFIER_SETTING = "PRODUCT_BUNDLE_IDENTIFIER"
      INFO_PLIST_SETTING = "INFOPLIST_FILE"
      INFO_PLIST_BUNDLE_IDENTIFIER_KEY = "CFBundleIdentifier"
      INFO_PLIST_BUNDLE_MARKETING_VERSION_KEY = "CFBundleShortVersionString"

      def self.description
        "Archives and exports iOS apps"
      end

      def self.details
        "Archives an Xcode target with the provided options and exports it to IPAs"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :project,
            env_name: "LT_DISTRIBUTION_PROJECT",
            description: "Path to .xcodeproj file to build",
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Project file not found at path '#{value}'") unless File.exist?(value)
              UI.user_error!("Invalid project file") unless File.directory?(value)
              unless value.end_with?(".xcodeproj")
                UI.user_error!("Project file is not a project, must end with .xcodeproj")
              end
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :scheme,
            env_name: "LT_DISTRIBUTION_SCHEME",
            description: "Scheme in project to archive",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :other_flags,
            env_name: "LT_DISTRIBUTION_OTHER_FLAGS",
            description: "Additional flags to pass to xcodebuild",
            type: String,
            optional: true,
            default_value: ""
          ),
          FastlaneCore::ConfigItem.new(
            key: :technical_version,
            env_name: "LT_DISTRIBUTION_TECHNICAL_VERSION",
            description: "Build number to use for this build",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :provisioning_profile_prefix,
            env_name: "LT_DISTRIBUTION_PROVISIONING_PROFILE_PREFIX",
            description: "The prefix for the provisioning profiles for the application, this is " \
                         "usually the full name of the application",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :defines_prefix,
            env_name: "LT_DISTRIBUTION_DEFINES_PREFIX",
            description: "The compilation is done with preprocessor definitions indicating the " \
                         "type of the build (distribution, beta, production). The option states " \
                         "prefix for this definitions",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :applestore_demo,
            env_name: "LT_DISTRIBUTION_APPLESTORE_DEMO",
            description: "Whether to build a demo app for Apple retail stores. The value of this " \
                         "option is passed to the LT_APPLESTORE_DEMO flag, and the bundle " \
                         "identifier is appended with \".retaildemo\"",
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :beta,
            env_name: "LT_DISTRIBUTION_BETA",
            description: "Whether to build an application intended for internal distribution. " \
                         "The value of this option is passed to the \"LT_BETA_BUILD\" " \
                         "definition",
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :production,
            env_name: "LT_DISTRIBUTION_PRODUCTION",
            description: "Whether to build an application intended for external distribution, " \
                         "i.e. AppStore. The value of this option is passed to the " \
                         "\"LT_PRODUCTION_BUILD\" preprocessor definition",
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :ad_hoc_export,
            env_name: "LT_DISTRIBUTION_AD_HOC_EXPORT",
            description: "Whether to produce an IPA signed ad-hoc distribution",
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_store_export,
            env_name: "LT_DISTRIBUTION_APP_STORE_EXPORT",
            description: "Whether to produce an IPA signed for the app store",
            type: Boolean,
            default_value: false
          )
        ]
      end

      # Returns the path to the Info.plist for for the given target and configuration. The path is
      # derived from the path of the project of the target.
      def self.fetch_plist_info_path(target, configuration)
        plist_base_path = target.resolved_build_setting(INFO_PLIST_SETTING)[configuration]
        File.join(File.dirname(target.project.path), plist_base_path)
      end

      # Reads the Info.plist file for the given target and configuration. Returns the value for the
      # given key.
      def self.read_plist_info_value(target, configuration, key)
        plist_path = fetch_plist_info_path(target, configuration)
        other_action.get_info_plist_value(path: plist_path, key: key)
      end

      # Iterates over all the targets in project and returns the target with the same name as the
      # given scheme.
      def self.fetch_main_target(project, scheme)
        main_target = project.targets.find { |target| target.name == scheme }
        if main_target.nil?
          UI.user_error!("The project at #{project_path} does not contain target with name " \
                         "#{scheme}")
        end

        main_target
      end

      # Returns the base bundle identifier as defined in the base project of the given project.
      def self.fetch_base_bundle_identifier(project)
        base_bundle_identifier = project.build_settings("Release")["LT_BASE_PRODUCT_IDENTIFIER"]
        if base_bundle_identifier.nil?
          UI.user_error!("Base project is expected to contain LT_BASE_PRODUCT_IDENTIFIER setting")
        end

        base_bundle_identifier
      end

      # Extract the marketing version from the plist of the main target.
      def self.fetch_marketing_version(target)
        read_plist_info_value(target, "Release", INFO_PLIST_BUNDLE_MARKETING_VERSION_KEY)
      end

      # Enumerate the given main_target and dependent targets that need signing. For each target:
      #   1. Verify the bundle identifier setting uses LT_BASE_PRODUCT_IDENTIFIER.
      #   2. Verify the Info.plist file is using the bundle identifier from the build settings.
      #   3. Set the setting required for apple retail store builds.
      #   4. Set technical_version and marketing_version.
      def self.update_info_plists(main_target, technical_version, marketing_version,
                                  applestore_demo)
        targets_to_sign =
          [main_target] + main_target.project.embedded_targets_in_native_target(main_target)
        targets_to_sign.each do |target|
          target_bundle_identifier =
            target.resolved_build_setting(BUNDLE_IDENTIFIER_SETTING)["Release"]
          if target == main_target
            unless target_bundle_identifier == "$(LT_BASE_PRODUCT_IDENTIFIER)"
              UI.user_error!("#{BUNDLE_IDENTIFIER_SETTING} for target #{target.name} is not " \
                             "$(LT_BASE_PRODUCT_IDENTIFIER)")
            end
          else
            unless target_bundle_identifier.include?("$(LT_BASE_PRODUCT_IDENTIFIER)")
              UI.user_error!("#{BUNDLE_IDENTIFIER_SETTING} for target #{target.name} does not " \
                             "contain $(LT_BASE_PRODUCT_IDENTIFIER)")
            end
          end

          plist_bundle_identifier =
            read_plist_info_value(target, "Release", INFO_PLIST_BUNDLE_IDENTIFIER_KEY)
          if plist_bundle_identifier != "$(#{BUNDLE_IDENTIFIER_SETTING})"
            UI.user_error!("Expected bundle indentifer in Info.plist to be " \
                           "$(#{BUNDLE_IDENTIFIER_SETTING}. Got #{plist_bundle_identifier}.")
          end

          plist_path = fetch_plist_info_path(target, "Release")
          other_action.update_plist(
            plist_path: plist_path,
            block: proc do |plist|
              plist["UIApplicationExitsOnSuspend"] = true if applestore_demo
              plist["CFBundleVersion"] = technical_version
              plist["CFBundleShortVersionString"] = marketing_version
              UI.important("Processing plist file #{plist_path}")
              UI.important("Marketing version: #{plist['CFBundleShortVersionString']}")
              UI.important("Technical version: #{plist['CFBundleVersion']}")
            end
          )
        end
      end

      def self.run(params)
        project_path = params[:project]
        applestore_demo = params[:applestore_demo]
        scheme = params[:scheme]
        technical_version = params[:technical_version]
        provisioning_profile_prefix = params[:provisioning_profile_prefix]
        defines_prefix = params[:defines_prefix]

        project = Xcodeproj::Project.open(project_path)
        main_target = fetch_main_target(project, scheme)
        marketing_version = fetch_marketing_version(main_target)
        update_info_plists(main_target, technical_version, marketing_version, applestore_demo)

        base_bundle_identifier = fetch_base_bundle_identifier(project)
        base_bundle_identifier_retail_demo = base_bundle_identifier + ".retaildemo"

        bundle_identifier = base_bundle_identifier
        bundle_identifier = base_bundle_identifier_retail_demo if applestore_demo

        UI.important("Using base bundle identifier #{bundle_identifier}")

        preprocessor_flags = ["\\${inherited}",
                              "LOGGING=1",
                              "#{defines_prefix}_DISTRIBUTION_BUILD=1",
                              "#{defines_prefix}_BETA_BUILD=#{params[:beta]}",
                              "#{defines_prefix}_PRODUCTION_BUILD=#{params[:production]}",
                              "LT_DISTRIBUTION_BUILD=1",
                              "LT_BETA_BUILD=#{params[:beta]}",
                              "LT_PRODUCTION_BUILD=#{params[:production]}",
                              "LT_APPLESTORE_DEMO=#{params[:applestore_demo]}",
                              "DISTRIBUTION_BUILD=1",
                              "BETA_BUILD=#{params[:beta]}",
                              "PRODUCTION_BUILD=#{params[:production]}",
                              "APPLESTORE_DEMO=#{params[:applestore_demo]}"].join(" ")

        xcargs = ["VALID_ARCHS=arm64",
                  "TREAT_WARNINGS_AS_ERRORS=YES",
                  "LT_BASE_PRODUCT_IDENTIFIER=#{bundle_identifier}",
                  "GCC_PREPROCESSOR_DEFINITIONS=\"#{preprocessor_flags}\"",
                  params[:other_flags]].join(" ")

        build_type = applestore_demo ? "apple-store" : "standard"
        output_prefix = [scheme, build_type, marketing_version, technical_version].join("-")
        archive_path = "output/archive/#{scheme}.xcarchive"
        ad_hoc_ipa_path = "#{output_prefix}-ad-hoc.ipa"
        app_store_ipa_path = "#{output_prefix}-app-store.ipa"
        output_directory = "output"

        other_action.build_ios_app(
          project: project_path,
          scheme: scheme,
          clean: true,
          output_directory: output_directory,
          archive_path: archive_path,
          xcargs: xcargs,
          sdk: "iphoneos",
          skip_profile_detection: true,
          skip_package_ipa: true,
          buildlog_path: "output/log"
        )

        if params[:ad_hoc_export]
          other_action.build_ios_app(
            project: project_path,
            scheme: scheme,
            output_directory: output_directory,
            archive_path: archive_path,
            skip_build_archive: true,
            skip_profile_detection: true,
            output_name: ad_hoc_ipa_path,
            export_options: {
              "method": "ad-hoc",
              "teamID": "KG6GWND6BG",
              "iCloudContainerEnvironment": "Development",
              provisioningProfiles: {
                "#{base_bundle_identifier}":
                    "#{provisioning_profile_prefix} Distribution Profile",
                "#{base_bundle_identifier_retail_demo}":
                    "#{provisioning_profile_prefix} Demo Distribution Profile"
              }
            }
          )
          Actions.lane_context[SharedValues::ADHOC_IPA_OUTPUT_PATH] = File.join(output_directory,
                                                                                ad_hoc_ipa_path)
        end

        if params[:app_store_export]
          other_action.build_ios_app(
            project: project_path,
            scheme: scheme,
            output_directory: output_directory,
            archive_path: archive_path,
            skip_build_archive: true,
            skip_profile_detection: true,
            output_name: app_store_ipa_path,
            export_options: {
              "method": "app-store",
              "teamID": "KG6GWND6BG",
              "iCloudContainerEnvironment": "Production",
              provisioningProfiles: {
                "#{base_bundle_identifier}":
                    "#{provisioning_profile_prefix} App Store Distribution Profile",
                "#{base_bundle_identifier_retail_demo}":
                    "#{provisioning_profile_prefix} Demo App Store Distribution Profile"
              }
            }
          )
          Actions.lane_context[SharedValues::APPSTORE_IPA_OUTPUT_PATH] =
            File.join(output_directory, app_store_ipa_path)
        end

        # Disallow the use of automatic IPA path generated by fastlane, since both ad-hoc and
        # app-store IPAs are needed for other actions like uploading to Crashlytics or iTunes
        # connect.
        Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] = nil
        ENV[SharedValues::IPA_OUTPUT_PATH.to_s] = nil
      end
    end
  end
end

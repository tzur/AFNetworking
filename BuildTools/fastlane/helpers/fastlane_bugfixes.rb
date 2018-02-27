# frozen_string_literal: true

module Fastlane
  # Open this class to fix a bug in fastlane which causes actions called by other actions to have
  # their workspace directory (PWD) the "fastlane" directory instead of the root directory of the
  # repo.
  class OtherAction
    # rubocop:disable Style/MethodMissing
    def method_missing(method_sym, *arguments, &_block)
      # rubocop:enable Style/MethodMissing
      runner.trigger_action_by_name(method_sym,
                                    File.expand_path("..", FastlaneCore::FastlaneFolder.path),
                                    true,
                                    *arguments)
    end
  end
end

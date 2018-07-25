# frozen_string_literal: true

require_relative "junit_helper"

module Fastlane
  module Actions
    module Helpers
      BASE_DIR_ABSOLUTE_PATH = File.expand_path("..", File.dirname(__FILE__))

      def self.script_path(filename = "")
        File.join(BASE_DIR_ABSOLUTE_PATH, "scripts", filename)
      end

      def self.resource_path(filename = "")
        File.join(BASE_DIR_ABSOLUTE_PATH, "resources", filename)
      end

      def self.kill_simulators
        `killall Simulator 1> /dev/null 2>&1`
      end
    end
  end
end

# Copyright (c) 2017 Lightricks. All rights reserved.

require 'jsonlint'

module Danger
  # Checks for invalid JSON files.
  class JsonLinter < Plugin
    def lint(files = nil)
      changed_json_files = get_json_files(files)
      return unless changed_json_files

      json_linter = JsonLint::Linter.new
      json_linter.check_all(changed_json_files)
      return unless json_linter.errors?

      markdown get_pretty_error_message(json_linter.errors)
    end

    def get_json_files(files)
      files.select { |filepath| File.extname(filepath).casecmp?('.json') }
    end

    def get_pretty_error_message(json_errors)
      message = []
      message << '### JSON files issues'
      message << '| File | Error |'
      message << '| ---- | ----- |'
      json_errors.each do |path, errors|
        errors.each { |err| message << "| #{github.html_link(path)} |  #{err} |" }
      end
      message * "\n"
    end
  end
end

# Copyright (c) 2017 Lightricks. All rights reserved.

module Danger
  # Makes sure the commits follow to following rules:
  # * Commit subject should be in the format "Component: What changed" or "++Submodule".
  # * Commit subject should end with a period.
  # * Commit subject should be no longer than 72 characters.
  # * Empty line should separate between commit subject and body.
  # * Commit body should end with a period.
  # * Commit body should wrap around 72 characters.
  # * Commiter email should be a valid Lightricks email.
  class CommitLinter < Plugin
    COMMIT_SUBJECT_MAX_CHARACTERS = 72
    COMMIT_BODY_MAX_LINE_CHARACTERS = 72
    COMMIT_SUBJECT_REGEX = /(\S+: \S+|\+\+\S+)/

    def lint
      git.commits.each do |commit|
        lint_commit commit
      end
    end

    def lint_commit_subject(commit, subject)
      unless subject =~ COMMIT_SUBJECT_REGEX
        warn "Commit #{commit.sha} subject must be in the form \"Component: What changed.\" or "\
             '++Submodule.'
      end

      unless subject.end_with? '.'
        warn "Commit #{commit.sha} subject doesn't end with a period"
      end

      # rubocop:disable Style/GuardClause
      if subject.length > COMMIT_SUBJECT_MAX_CHARACTERS
        warn "Commit #{commit.sha} subject is longer than #{COMMIT_SUBJECT_MAX_CHARACTERS} "\
             'characters'
      end
    end

    def lint_commit_body(commit, body)
      return unless body

      unless body.end_with? '.'
        warn "Commit #{commit.sha} body doesn't end with a period"
      end

      body.split("\n").each_with_index do |body_line, index|
        if body_line.chomp.length > COMMIT_BODY_MAX_LINE_CHARACTERS
          warn "Commit #{commit.sha} body line number #{index + 1} is longer than "\
               "#{COMMIT_BODY_MAX_LINE_CHARACTERS} characters"
        end
      end
    end

    def lint_commit(commit)
      (subject, second_message_line, *body_arr) = commit.message.split("\n")
      body = !body_arr.empty? ? body_arr.join("\n") : nil

      if second_message_line && !second_message_line.empty?
        warn "Commit #{commit.sha} must separate subject and body with two newlines"
      end

      unless commit.author.email.downcase.end_with? '@lightricks.com'
        warn "Commit #{commit.sha} author has non Lightricks email address"
      end

      lint_commit_subject commit, subject
      lint_commit_body commit, body
    end
  end
end

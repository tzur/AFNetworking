# frozen_string_literal: true

require "fastlane"

# Helper class to execute arbitrary commands.
class Executor
  UNKNOWN_EXIT_CODE = 1337

  # Execute that given command and waits for the process to complete.
  # This was created due to the fact that fastlane's execution engine mixes pipes stderr to stdout
  # which prevents from analyzing stderr independently. This implementation does not touch
  # stderr.
  #
  # @params command (String): Shell command to execute.
  def self.execute(command)
    Fastlane::UI.command(command)
    exit_code = UNKNOWN_EXIT_CODE
    output = []
    Open3.popen2(command) do |_stdin, stdout, wait_thr|
      stdout.each do |l|
        line = l.strip # strip so that \n gets removed
        output << line
        Fastlane::UI.command_output(line)
      end

      status = wait_thr.value
      unless status.success?
        Fastlane::UI.error("Command \"#{command}\" exited with code #{status.exitstatus}")
      end
      exit_code = status.exitstatus
    end

    [exit_code, output]
  end
end

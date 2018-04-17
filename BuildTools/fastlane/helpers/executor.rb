# frozen_string_literal: true

require "fastlane"

# Helper class to execute arbitrary commands.
class Executor
  UNKNOWN_EXIT_CODE = 1337

  # Execute that given command and waits for the process to complete.
  # This was created due to the fact that fastlane's execution engine pipes stderr to stdout
  # which prevents from analyzing stderr independently. Both stdout and stderr go through fastlane's
  # UI and piped to stdout.
  #
  # @params command (String) shell command to execute.
  # @return [Array] where the first object is the exit code of the command, the second is the data
  # from stdout and the third it the data from stderr.
  def self.execute(command)
    Fastlane::UI.command(command)
    exit_code = UNKNOWN_EXIT_CODE
    output = []
    errors = []
    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      open_file_descriptors = [stdout, stderr]

      until open_file_descriptors.empty?
        IO.select(open_file_descriptors)[0].each do |fd|
          begin
            line = fd.readline.strip # strip so that \n gets removed
          rescue EOFError
            open_file_descriptors.delete fd
            next
          end

          if fd == stdout
            output << line
            Fastlane::UI.command_output(line)
          end

          if fd == stderr
            errors << line
            Fastlane::UI.error(line)
          end
        end
      end

      status = wait_thr.value
      unless status.success?
        Fastlane::UI.error("Command \"#{command}\" exited with code #{status.exitstatus}")
      end
      exit_code = status.exitstatus
    end

    [exit_code, output, errors]
  end
end

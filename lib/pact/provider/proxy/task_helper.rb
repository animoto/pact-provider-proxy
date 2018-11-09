require 'pact/provider/pact_helper_locator'
require 'rake/file_utils'

module Pact
  module Provider
    module Proxy
      module TaskHelper

        extend self

        def execute_pact_verify pact_uri = nil, pact_helper = nil, rspec_opts
          execute_cmd verify_command(pact_helper, pact_uri, rspec_opts)
        end

        def handle_verification_failure
          exit_status = yield
          abort if exit_status != 0
        end

        def verify_command pact_helper, pact_uri = nil, rspec_opts
          command_parts = []
	  # Clear SPEC_OPTS, otherwise we can get extra formatters, creating duplicate output eg. CI Reporting.
          # Allow deliberate configuration using rspec_opts in VerificationTask.
          command_parts << "SPEC_OPTS=#{Shellwords.escape(rspec_opts || '')}"
          command_parts << FileUtils::RUBY
          command_parts << "-S pact verify"
          command_parts << "-h" << (pact_helper.end_with?(".rb") ? pact_helper : pact_helper + ".rb")
          (command_parts << "-p" << pact_uri) if pact_uri
          command_parts << "--description #{Shellwords.escape(ENV['PACT_DESCRIPTION'])}" if ENV['PACT_DESCRIPTION']
          command_parts << "--provider-state #{Shellwords.escape(ENV['PACT_PROVIDER_STATE'])}" if ENV['PACT_PROVIDER_STATE']
          command_parts << "--backtrace" if ENV['BACKTRACE'] == 'true'
          command_parts.flatten.join(" ")
        end

        def execute_cmd command
          system(command) ? 0 : 1
        end

      end

    end
  end
end

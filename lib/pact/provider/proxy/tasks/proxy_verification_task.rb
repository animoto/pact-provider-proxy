require 'rake/tasklib'

module Pact
  class ProxyVerificationTask < ::Rake::TaskLib

    attr_reader :pact_spec_configs
    attr_accessor :rspec_opts

    def initialize(name)
      @rspec_opts = nil
      @pact_spec_configs = []
      @provider_base_url = nil
      @name = name
      @publish_verification_results = false
      @provider_app_version = nil
      yield self
      rake_task
    end


    def pact_url(uri, options = {})
      @pact_spec_configs << {uri: uri, pact_helper: options[:pact_helper]}
    end

    # For compatiblity with the normal VerificationTask, allow task.uri
    alias_method :uri, :pact_url

    def provider_base_url url
      @provider_base_url = url
    end

    def provider_app_version provider_app_version
      @provider_app_version = provider_app_version
    end

    def publish_verification_results publish_verification_results
      @publish_verification_results = publish_verification_results
    end

    private

    attr_reader :name

    def rake_task
      namespace :pact do
        desc "Verify running provider against the consumer pacts for #{name}"
        task "verify:#{name}" do |t, args|

          require 'pact/provider/proxy/task_helper'

          proxy_pact_helper = File.expand_path('../../proxy_pact_helper.rb', __FILE__)

          exit_statuses = pact_spec_configs.collect do | config |
            ENV['PACT_PROVIDER_BASE_URL'] = @provider_base_url
            ENV['PACT_PROJECT_PACT_HELPER'] = config[:pact_helper]
            ENV['PACT_PROVIDER_APP_VERSION'] = @provider_app_version
            ENV['PACT_PUBLISH_VERIFICATION_RESULTS'] = "#{@publish_verification_results}"
            Pact::Provider::Proxy::TaskHelper.execute_pact_verify config[:uri], proxy_pact_helper, rspec_opts
          end

          Pact::Provider::Proxy::TaskHelper.handle_verification_failure do
            exit_statuses.count{ | status | status != 0 }
          end

        end
      end
    end
  end
end

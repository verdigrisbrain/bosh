module Bosh::Director
  class LogsFetcher
    def initialize(event_log, instance_manager, log_bundles_cleaner, logger)
      @event_log = event_log
      @instance_manager = instance_manager
      @log_bundles_cleaner = log_bundles_cleaner
      @logger = logger
    end

    # @param [Models::Instance] instance
    # @param [String] log_type
    # @param [Array] filters
    def fetch(instance, log_type, filters)
      @log_bundles_cleaner.clean

      stage = @event_log.begin_stage("Fetching logs for #{instance.job}/#{instance.index}", 1)

      agent = @instance_manager.agent_client_for(instance)

      blobstore_id = nil

      stage.advance_and_track('Finding and packing log files') do
        @logger.info("Fetching logs from agent: log_type='#{log_type}', filters='#{filters}'")
        fetch_logs_result = agent.fetch_logs(log_type, filters)
        blobstore_id = fetch_logs_result['blobstore_id']
      end

      if blobstore_id.nil?
        raise AgentTaskNoBlobstoreId,
              "Agent didn't return a blobstore object id for packaged logs"
      end

      @log_bundles_cleaner.register_blobstore_id(blobstore_id)

      blobstore_id
    end
  end
end
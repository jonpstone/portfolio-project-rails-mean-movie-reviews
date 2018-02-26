# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'ipaddr'
require 'timeout'
require 'json'

require 'sqreen/events/attack'

require 'sqreen/log'

require 'sqreen/rules'
require 'sqreen/session'
require 'sqreen/remote_command'
require 'sqreen/capped_queue'
require 'sqreen/metrics_store'
require 'sqreen/deliveries/simple'
require 'sqreen/deliveries/batch'
require 'sqreen/performance_notifications/metrics'
require 'sqreen/instrumentation'
require 'sqreen/call_countable'

module Sqreen
  @features = {}
  @queue = nil

  # Event Queue that enable communication between threads and the reporter
  MAX_QUEUE_LENGTH = 100
  MAX_OBS_QUEUE_LENGTH = 1000

  METRICS_EVENT = 'metrics'.freeze

  class << self
    attr_reader :features
    def update_features(features)
      @features = features
    end

    def queue
      @queue ||= CappedQueue.new(MAX_QUEUE_LENGTH)
    end

    def observations_queue
      @observations_queue ||= CappedQueue.new(MAX_OBS_QUEUE_LENGTH)
    end

    attr_accessor :instrumentation_ready
    alias instrumentation_ready? instrumentation_ready

    attr_accessor :logged_in
    alias logged_in? logged_in

    attr_reader :whitelisted_paths
    def update_whitelisted_paths(paths)
      @whitelisted_paths = paths.freeze
    end

    attr_reader :whitelisted_ips
    def update_whitelisted_ips(paths)
      @whitelisted_ips = Hash[paths.map { |v| [v, IPAddr.new(v)] }].freeze
    end
  end

  # Main running job class for the agent
  class Runner
    # During one hour
    HEARTBEAT_WARMUP = 60 * 60
    # Initail delay is 5 minutes
    HEARTBEAT_MAX_DELAY = 5 * 60

    attr_accessor :heartbeat_delay
    attr_accessor :metrics_engine
    attr_reader :deliverer
    attr_reader :session
    attr_reader :instrumenter
    attr_accessor :running
    attr_accessor :next_command_results
    attr_accessor :next_metrics

    # we may want to do that in a thread in order to prevent delaying app
    # startup
    # set_at_exit do not place a global at_exit (used for testing)
    def initialize(configuration, framework, set_at_exit = true, session_class = Sqreen::Session)
      @logged_out_tried = false
      @configuration = configuration
      @framework = framework
      @heartbeat_delay = HEARTBEAT_MAX_DELAY
      @last_heartbeat_request = Time.now
      @next_command_results = {}
      @next_metrics = []
      @running = true

      @token = @configuration.get(:token)
      @url = @configuration.get(:url)
      Sqreen.update_whitelisted_paths([])
      Sqreen.update_whitelisted_ips({})
      raise(Sqreen::Exception, 'no url found') unless @url
      raise(Sqreen::TokenNotFoundException, 'no token found') unless @token

      register_exit_cb if set_at_exit

      self.metrics_engine = MetricsStore.new
      @instrumenter = Instrumentation.new(metrics_engine)

      Sqreen.log.warn "using token #{@token}"
      response = create_session(session_class)
      wanted_features = response.fetch('features', {})
      conf_initial_features = configuration.get(:initial_features)
      unless conf_initial_features.nil?
        begin
          conf_features = JSON.parse(conf_initial_features)
          raise 'Invalid Type' unless conf_features.is_a?(Hash)
          Sqreen.log.debug do
            "Override initial features with #{conf_features.inspect}"
          end
          wanted_features = conf_features
        rescue
          Sqreen.log.warn do
            "NOT using invalid inital features #{conf_initial_features}"
          end
        end
      end
      self.features = wanted_features

      # Ensure a deliverer is there unless features have set it first
      self.deliverer ||= Deliveries::Simple.new(session)
      context_infos = {}
      %w[rules pack_id].each do |p|
        context_infos[p] = response[p] unless response[p].nil?
      end
      process_commands(response.fetch('commands', []), context_infos)
    end

    def create_session(session_class)
      @session = session_class.new(@url, @token)
      session.login(@framework)
    end

    def deliverer=(new_deliverer)
      deliverer.drain if deliverer
      @deliverer = new_deliverer
    end

    def batch_events(batch_size, max_staleness = nil)
      size = batch_size.to_i
      self.deliverer = if size < 1
                         Deliveries::Simple.new(session)
                       else
                         staleness = max_staleness.to_i
                         Deliveries::Batch.new(session, size, staleness)
                       end
    end

    def load_rules(context_infos = {})
      rules_pack = context_infos['rules']
      rulespack_id = context_infos['pack_id']
      if rules_pack.nil? || rulespack_id.nil?
        session_rules = session.rules
        rules_pack = session_rules['rules']
        rulespack_id = session_rules['pack_id']
      end
      rules = rules_pack.each { |r| r['rulespack_id'] = rulespack_id }
      Sqreen.log.info { format('retrieved rulespack id: %s', rulespack_id) }
      Sqreen.log.debug { format('retrieved %d rules', rules.size) }
      local_rules = Sqreen::Rules.local(@configuration) || []
      rules += local_rules.
               select { |rule| rule['enabled'] }.
               each { |r| r['rulespack_id'] = 'local' }
      Sqreen.log.debug do
        format('rules: %s', rules.
               sort_by { |r| r['name'] }.
               map { |r| format('(%s, %s, %s)', r[Rules::Attrs::NAME], r.to_json.size, r[Rules::Attrs::BLOCK]) }.
               join(', '))
      end
      [rulespack_id, rules]
    end

    def call_counts_metrics_period=(value)
      value = value.to_i
      return unless value > 0 # else disable collection?
      metrics_engine.create_metric('name' => CallCountable::COUNT_CALLS,
                                   'period' => value,
                                   'kind' => 'Sum')
    end

    def performance_metrics_period=(value)
      value = value.to_i
      if value > 0
        PerformanceNotifications::Metrics.enable(metrics_engine, value)
      else
        PerformanceNotifications::Metrics.disable
      end
    end

    def setup_instrumentation(context_infos = {})
      Sqreen.log.info 'setup instrumentation'
      rulespack_id, rules = load_rules(context_infos)
      @framework.instrument_when_ready!(instrumenter, rules)
      rulespack_id.to_s
    end

    def remove_instrumentation(_context_infos = {})
      Sqreen.log.debug 'removing instrumentation'
      instrumenter.remove_all_callbacks
      true
    end

    def reload_rules(_context_infos = {})
      Sqreen.log.debug 'Reloading rules'
      rulespack_id, rules = load_rules
      instrumenter.remove_all_callbacks

      @framework.instrument_when_ready!(instrumenter, rules)
      Sqreen.log.debug 'Rules reloaded'
      rulespack_id.to_s
    end

    def process_commands(commands, context_infos = {})
      return if commands.nil? || commands.empty?
      res = RemoteCommand.process_list(self, commands, context_infos)
      @next_command_results = res
    end

    def do_heartbeat
      @last_heartbeat_request = Time.now
      @next_metrics.concat(metrics_engine.publish(false)) if metrics_engine
      res = session.heartbeat(next_command_results, next_metrics)
      next_command_results.clear
      next_metrics.clear
      process_commands(res['commands'])
    end

    def features(_context_infos = {})
      Sqreen.features
    end

    def features=(features)
      Sqreen.update_features(features)
      session.request_compression = features['request_compression'] if session
      self.performance_metrics_period = features['performance_metrics_period']
      self.call_counts_metrics_period = features['call_counts_metrics_period']
      hd = features['heartbeat_delay'].to_i
      self.heartbeat_delay = hd if hd > 0
      return if features['batch_size'].nil?
      batch_events(features['batch_size'], features['max_staleness'])
    end

    def change_whitelisted_paths(paths, _context_infos = {})
      return false unless paths.respond_to?(:each)
      Sqreen.update_whitelisted_paths(paths)
      true
    end

    def upload_bundle(_context_infos = {})
      t = Time.now
      session.post_bundle(RuntimeInfos.dependencies_signature, RuntimeInfos.dependencies)
      Time.now - t
    end

    def change_whitelisted_ips(ips, _context_infos = {})
      return false unless ips.respond_to?(:each)
      Sqreen.update_whitelisted_ips(ips)
      true
    end

    def change_features(new_features, _context_infos = {})
      old = features
      self.features = new_features
      {
        'was' => old,
        'now' => new_features,
      }
    end

    def aggregate_observations
      q = Sqreen.observations_queue
      q.size.times do
        cat, key, obs, t = q.pop
        metrics_engine.update(cat, t, key, obs)
      end
    end

    def heartbeat_needed?
      (@last_heartbeat_request + heartbeat_delay) < Time.now
    end

    def run_watcher_once
      event = Timeout.timeout(heartbeat_delay) do
        Sqreen.queue.pop
      end
    rescue Timeout::Error
      periodic_cleanup
    else
      handle_event(event)
      if heartbeat_needed?
        # Also aggregate/post metrics when cleanup has
        # not been done for a long time
        Sqreen.log.debug 'Forced an heartbeat'
        periodic_cleanup # will trigger do_heartbeat since it's time
      end
    end

    def periodic_cleanup
      # Nothing occured:
      # tick delivery, aggregates_metrics
      # issue a simple heartbeat if it's time (which may return commands)
      @deliverer.tick
      aggregate_observations
      do_heartbeat if heartbeat_needed?
    end

    def handle_event(event)
      if event == METRICS_EVENT
        aggregate_observations
      else
        @deliverer.post_event(event)
      end
    end

    def run_watcher
      run_watcher_once while running
    end

    # Sinatra is using at_exit to run the application, see:
    # https://github.com/sinatra/sinatra/blob/cd503e6c590cd48c2c9bb7869522494bfc62cb14/lib/sinatra/main.rb#L25
    def exit_from_sinatra_startup?
      defined?(Sinatra::Application) &&
        Sinatra::Application.respond_to?(:run?) &&
        !Sinatra::Application.run?
    end

    def shutdown(_context_infos = {})
      remove_instrumentation
      logout
    end

    def logout(retrying = true)
      return unless session
      if @framework.development?
        @running = false
        return
      end
      if @logged_out_tried
        Sqreen.log.debug('Not running logout twice')
        return
      end
      @logged_out_tried = true
      @deliverer.drain if @deliverer
      aggregate_observations
      session.post_metrics(metrics_engine.publish) if metrics_engine
      session.logout(retrying)
      @running = false
    end

    def register_exit_cb(try_again = true)
      at_exit do
        if exit_from_sinatra_startup? && try_again
          register_exit_cb(false)
        else
          logout
        end
      end
    end
  end
end

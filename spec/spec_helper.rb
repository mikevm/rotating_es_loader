# frozen_string_literal: true

require 'elasticsearch/extensions/test/cluster'

ES_PORT = 9_250

def start_elasticsearch
  Elasticsearch::Extensions::Test::Cluster.start(
    port: ES_PORT,
    nodes: 1,
    timeout: 120
  )
end

def stop_elasticsearch
  Elasticsearch::Extensions::Test::Cluster.stop(port: ES_PORT, nodes: 1)
end

def elasticsearch_running?
  Elasticsearch::Extensions::Test::Cluster.running?(on: ES_PORT)
end

RSpec.configure do |config|
  # Start an in-memory cluster for Elasticsearch as needed
  config.before :all, elasticsearch: true do
    start_elasticsearch unless elasticsearch_running?
  end

  # Stop elasticsearch cluster after test run
  config.after :suite do
    stop_elasticsearch if elasticsearch_running?
  end

  config.before :each, elasticsearch: true do
  end

  config.after :each, elasticsearch: true do
  end
end

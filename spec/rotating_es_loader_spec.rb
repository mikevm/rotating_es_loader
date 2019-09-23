# frozen_string_literal: true

require_relative './spec_helper'
require './lib/rotating_es_loader'

RSpec.describe RotatingEsLoader, elasticsearch: true do
  # TODO: mock credentials
  let(:credentials) { Aws::SharedCredentials.new }

  describe 'constructor' do
    it 'fails to instantiate without a url' do
      expect do
        RotatingEsLoader.new(
          index_keys: %w[docs],
          credentials: credentials,
          mappings: {},
          datasources: {}
        )
      end.to raise_error(RuntimeError)
    end

    it 'instantiates correctly' do
      RotatingEsLoader.new(
        index_keys: %w[docs],
        url: 'http://localhost:9250',
        credentials: credentials,
        mappings: {},
        datasources: {}
      )
    end
  end
end

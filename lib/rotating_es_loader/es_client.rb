# frozen_string_literal: true

require 'faraday_middleware/aws_signers_v4'
require 'faraday_middleware/gzip'
require 'elasticsearch'
require 'memoist'
require 'logger'
require 'aws-sdk'

# :nodoc
class EsClient
  extend Memoist

  def initialize(
    url:,
    credentials:,
    logger: nil
  )

    raise('credentials must be an Aws::SharedCredentials') unless \
      credentials.is_a?(Aws::SharedCredentials)

    @logger = logger || Logger.new(STDOUT)
    @url = url
    @credentials = credentials
    @logger.info('URL is ' + url)
  end

  def client
    Elasticsearch::Client.new(url: @url) do |f|
      f.use FaradayMiddleware::Gzip
      f.request :aws_signers_v4,
                credentials: @credentials,
                service_name: 'es',
                region: 'us-west-1'
    end
  end
  memoize :client

  def method_missing(m, *args, &block)
    @logger.debug("Delegating #{m}")
    client.send(m, *args, &block)
  end
end

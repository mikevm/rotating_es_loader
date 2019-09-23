# frozen_string_literal: true

require 'rotating_es_loader/es_client'

# :nodoc
class RotatingEsLoader < EsClient
  extend Memoist

  # indexs with a datestamp newer than this age will not be wiped
  MAX_INDEX_AGE = 3
  DEFAULT_SLICE_SIZE = 50

  attr_accessor :slice_size, :es_major_version

  def initialize(opts)
    raise('no credentials provided') unless opts[:credentials]
    raise('no url provided') unless opts[:url]
    raise('no definitions provided') unless opts[:index_definitions].is_a?(Hash)
    uri = URI.parse(opts[:url])

    super(
      url: opts[:url],
      credentials: opts[:credentials]
    )

    @index_definitions = opts[:index_definitions]
    @slice_size = opts[:slice_size] || DEFAULT_SLICE_SIZE

    @logger.debug("index keys: #{index_keys}")
    @datasources = opts[:datasources]

    index_keys.each do |key|
      raise("No datasource for #{key}") unless @index_definitions[key][:datasource].respond_to?(:each)
    end

    es_info = client.info
    @es_major_version = es_info['version']['number'].split('.').first.to_i
  end

  def document_type_for(key)
    raise "document type not supported for ES #{es_major_version}" \
      unless es_major_version <= 5
    @index_definitions[key][:type]
  end

  def index_keys
    @index_definitions.keys
  end

  def mappings_for(key)
    @index_definitions[key][:mappings]
  end

  def settings_for(key)
    @index_definitions[key][:settings]
  end

  def datasource_for(key)
    @index_definitions[key][:datasource]
  end

  def execute
    create_indices
    create_documents
    swap_aliases
    delete_old_indices
  end

  def multitype_support?
    return es_major_version <= 5
  end

  def create_documents
    index_keys.each do |k|
      create_documents_for_type(
        name: get_index_name(k),
        data: datasource_for(k),
        type: document_type_for(k)
      )
    end
  end

  def create_documents_for_type(name:, data:, type: nil)
    @logger.info("Creating documents of in index #{name} in batches of #{@slice_size}")
    data.lazy.each_slice(@slice_size).each_with_index do |slice, slice_num|
      @logger.debug("batch #{slice_num}: #{slice.size} docs")
      result = client.bulk(
        body: slice.flat_map do |rec|
          index_record = { index: { _index: name, _id: rec[:id] } }
          index_record[:index].merge!(_type: type) if es_major_version == 5

          [
            index_record,
            rec
          ]
        end
      )

      @logger.warn("ERRORS: #{JSON.pretty_generate(result)}") if result['errors']
    end
  end

  def create_indices
    index_keys.each do |k|
      create_index(name: get_index_name(k), key: k)
    end
  end

  def key_age(key)
    date_str = key.split('-')[1]
    if date_str && date_str.size == 8
      (Date.today - Date.parse(date_str)).to_i
    else
      0
    end
  end

  def get_index_name(key)
    # TODO: make it more sequential, so that it sorts correctly
    date_str = Date.today.to_s.gsub(/\D/, '') + '-' + Time.now.to_i.to_s + '-' + Process.pid.to_s
    raise("provided key #{key} is not a valid index") unless index_keys.include?(key)
    return key.to_s + '-' + date_str
  end
  memoize :get_index_name # otherwise time might change

  def delete_old_indices
    existing_indices = client.indices.get(index: '_all')

    @logger.debug("Existing indexes: #{existing_indices.keys}")

    index_keys.each do |index|
      keys = existing_indices.keys.select { |k| k.include?(index.to_s) }.sort
      keys_by_date = keys.group_by { |k| key_age(k) }
      keys_to_delete = []

      # delete all indexes, keeping one from each day for the last few days
      keys_by_date.each do |age, key_list|
        key_list.pop if age <= MAX_INDEX_AGE
        keys_to_delete += key_list
      end

      unless keys_to_delete.empty?
        @logger.debug("Deleting indexes #{keys_to_delete.join(', ')}")
        client.indices.delete index: keys_to_delete
      end
    end
  end

  def swap_aliases
    index_keys.each do |alias_name|
      index_name = get_index_name(alias_name)

      actions = [
        { add: { index: index_name, alias: alias_name } }
      ]

      @logger.debug("fetching any indices attached to alias #{alias_name}")
      begin
        client.indices.get_alias(name: alias_name).keys.each do |index_to_remove|
          actions.unshift(
            remove: { index: index_to_remove, alias: alias_name }
          )
        end
      rescue StandardError => e
        @logger.warn(e)
      end

      @logger.debug('update_aliases actions: ' + actions.to_json)

      client.indices.update_aliases body: {
        actions: actions
      }
    end
  end

  def mappings_adjusted_for_es_version(key)
    mapping_for_key = mappings_for(key) || @logger.warn("mappings does not contain a mapping for #{key}")
    mappings = {}
    if es_major_version < 6
      mappings[key] = { properties: mapping_for_key }
    else
      mappings[:properties] = mapping_for_key
    end

    mappings
  end

  def create_index(name:, key:)
    @logger.debug("creating index #{name}")

    mappings = mappings_adjusted_for_es_version(key)

    @logger.debug("mappings: #{mappings.to_json}")
    @logger.debug("creating index #{name}")

    client.indices.create({
      index: name,
      body: {
        settings: settings_for(key),
        mappings: mappings
      }
    }.tap { |x| puts JSON.pretty_generate(x) })
  end
end

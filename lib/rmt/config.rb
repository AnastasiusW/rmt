require 'config'
require_relative '../rmt'

Config.setup do |config|
  config.merge_nil_values = false
end

Config.load_and_set_settings(
  File.join(__dir__, '../../config/rmt.yml'),
  File.join(__dir__, '../../config/rmt.local.yml')
)

if ENV.fetch('RMT_ENV', 'development') == 'production'
  Settings.reload_from_files(
    '/etc/rmt.conf'
  )
end

module RMT::Config
  class << self
    def db_config(key = 'database')
      {
        'username' => Settings[key].username,
        'password' => Settings[key].password,
        'database' => Settings[key].database,
        'host'     => Settings[key].host     || 'localhost',
        'adapter'  => Settings[key].adapter  || 'mysql2',
        'encoding' => Settings[key].encoding || 'utf8',
        'timeout'  => Settings[key].timeout  || 5000,
        'pool'     => Settings[key].pool     || 5
      }
    end

    # This method checks whether or not deduplication should be done by hardlinks.
    # If hardlinks are not used, the file will be copied instead.
    def deduplication_by_hardlink?
      Settings.try(:mirroring).try(:dedup_method).to_s.to_sym != :copy
    end

    def mirror_src_files?
      ActiveModel::Type::Boolean.new.cast(Settings.try(:mirroring).try(:mirror_src))
    end

    WebServerConfig = Struct.new(
      'WebServerConfig',
      :max_threads, :min_threads, :workers,
      keyword_init: true
    )

    def web_server
      WebServerConfig.new(
        max_threads: validate_int(Settings.try(:web_server).try(:max_threads)) || 5,
        min_threads: validate_int(Settings.try(:web_server).try(:min_threads)) || 5,
        workers:     validate_int(Settings.try(:web_server).try(:workers))     || 2
      )
    end

    private

    def validate_int(value)
      converted_value = Integer(value) rescue nil
      return nil if converted_value.nil? || converted_value < 1

      converted_value
    end
  end
end

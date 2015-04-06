require "native"
require "promise"

module PouchDB
  require "pouchdb/conversion"
  require "pouchdb/database"
  require "pouchdb/all_documents"
  require "pouchdb/row"
  require "pouchdb/event_emitter"
  require "pouchdb/replication"

  # Replicate data from source to target. Both the source and target can be a
  # PouchDB instance or a string representing a CouchDB database URL or the name
  # of a local PouchDB database. If `options.live` is true, then this will track
  # future changes and also replicate them automatically. This method returns an
  # object with the method `cancel()`, which you call if you want to cancel live
  # replication.
  #
  # Replication is an event emitter like changes() and emits the "complete",
  # "active", "paused", "change", "denied" and "error" events.
  #
  # Example:
  #
  #   stream = PouchDB.replicate("mydb", "http://localhost:5984/mydb",
  #                              live: true, retry: true)
  #           .on "change" do
  #             # ...
  #           end.on "paused" do
  #             # ...
  #           end # ...
  #
  #  stream.cancel
  #
  # @param source [String, Database] A source database, local or URL
  # @param target [String, Database] A target database, local or URL
  # @param options [Hash] Optional arguments, defaulting to `false` unless
  #   specified
  #
  # @option options [Boolean] live If `true`, starts subscribing to future
  #   changes in the `source` database and continue replicating them
  # @option options [Boolean] retry If `true`, will attempt to retry
  #   replications in the case of failure (due to being offline), using a
  #   backoff algorithm that retries at longer and longer intervals until
  #   a connection is re-established. Only applicable if `live: true`
  # @option options [String] filter References a filter function from a
  #   design document to selectively get upgrades
  # @option options [Hash] query parameters to send to the filter function
  # @option options [Array<String>] doc_ids Only replicate docs with these
  #   ids
  # @option options [Fixnum] since Replicate changes after the given
  #   sequence number
  # @option options [Boolean] create_target Create target database if it
  #   does not exist. Only for server replications
  # @option options [Fixnum] batch_size Number of documents to process at a
  #   time. Defaults to 100. This affects the number of docs held in memory
  #   and the number sent at a time to the target server. You may need to
  #   adjust downward if targeting devices with low amounts of memory
  #   (e.g. phones) or if the documents are large in size (e.g. with
  #   attachments). If your documents are small in size, then increasing this
  #   number will probably speed replication up.
  # @option options [Fixnum] batches_limit Number of batches to process at a
  #   time. Defaults to 10. This (along with `batch_size`) controls how many
  #   docs are kept in memory at a time, so the maximum docs in memory at
  #   once would equal `batch_size` x `batches_limit`.
  #
  # @return [EventEmitter] An EventEmitter with the 'complete', 'active',
  #   'paused', 'change', 'denied' and 'error' events
  def self.replicate(source, target, options = {})
    s = database_as_string(source)
    t = database_as_string(target)
    EventEmitter.new(`PouchDB.replicate(#{s}, #{t}, #{options.to_n})`)
  end

  # Sync data from `source` to `target` and `target` to `src`. This is a
  # convenience method for bidirectional data replication. In other words,
  # this code:
  #
  #     PouchDB.replicate("mydb", "http://localhost:5984/mydb")
  #     PouchDB.replicate("http://localhost:5984/mydb", "mydb")
  #
  # is equivalent to this code:
  #
  #     PouchDB.sync("mydb", "http://localhost:5984/mydb")
  #
  # @see .replicate
  # @return [EventEmitter] An EventEmitter with the 'complete', 'active',
  #   'paused', 'change', 'denied' and 'error' events
  def self.sync(source, target, options = {})
    s = database_as_string(source)
    t = database_as_string(target)
    EventEmitter.new(`PouchDB.sync(#{s}, #{t}, #{options.to_n})`)
  end

  extend Conversion
end

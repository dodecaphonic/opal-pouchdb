# coding: utf-8
module PouchDB
  # Creates a Database, either interacting with it locally or remotely. If
  # remotely, the library will act as a CouchDB client.
  #
  # Unless explicitly noted, this wrapper follows the same API names and
  # conventions of the original JavaScript code, with the exception of not
  # providing the alternative between callbacks and promises on CRUD operations,
  # opting for promises in every stance. The only situations in which that is
  # not the case are those involving EventEmitter, where only providing promises
  # would break semantics.
  #
  # That means you can safely read the original documentation and translate it
  # directly to Ruby. An `options` Object will be an options Hash, an Object
  # representing a document will be a Hash in Ruby land.
  #
  # This is not a toll-free library. It tries to follow the principle of least
  # surprise, forcing it to convert PouchDB's promises to Opal promises and
  # Objects to Hashes. It's not that great of a price to pay for convenience.
  #
  # Basic usage:
  #
  #   db = PouchDB::Database.new(name: "awesome_db")
  #   db.put(_id: "doc-id", contents: "This is important").then do
  #     db.all_docs(include_docs: true).then do |docs|
  #       puts "Yay, #{docs.size} docs"
  #     end
  #   end.fail do |error|
  #     puts "This code is perfect, but something went wrong"
  #   end
  #
  # Refer to the PouchDB API and Getting Started guides for more.
  class Database
    include Native
    include Conversion

    # Creates a Database. If passed a URL, the Database will act as a CouchDB
    # client. Otherwise, data will be stored and queried locally.
    #
    # Notice that here we don't support the alternative between passing the name
    # or `options` as the first argument. As such, name must *always* be
    # passed in as a keyword argument. A KeyError will be thrown otherwise.
    #
    # @param [Hash] options The options for database creation
    # @option options [String] :name The name or URL of the database (mandatory)
    # @option options [Boolean] :auto_compaction This turns on auto compaction, which means
    #   compact() is called after every change (default: false)
    # @option options [String] :adapter One of 'idb', 'leveldb', 'websql', or 'http'.
    #   If unspecified, PouchDB will infer this automatically, preferring IndexedDB
    #   to WebSQL in browsers that support both (i.e. Chrome, Opera and Android 4.4+).
    # @option options [Hash] :ajax For CouchDB clients only. Refer to official doc
    #   for more info.
    # @raise [KeyError] if `:name` is not passed in as a keyword argument
    def initialize(options = {})
      @name = options.fetch(:name)
      super `new PouchDB(#{options.to_n})`
    end

    attr_reader :name

    # Deletes the database. Be aware this will not affect replicas.
    #
    # @option options [Hash] :ajax Refer to the official doc for more info.
    # @return [Promise<Hash>]
    def destroy(options = {})
      as_opal_promise(`#{@native}.destroy()`)
    end

    # Deletes a document from the database. It can be called in one of two ways:
    #
    #    db.remove(doc: <full document hash>)
    #    # or, alternatively
    #    db.remove(doc_id: <id>, doc_rev: <revision>)
    #
    # @param args [Hash] The arguments for the function
    # @option args [Hash] :doc A document with _id and _rev to be removed. If defined,
    #   :doc_id and :doc_rev will be ignored.
    # @option args [String] :doc_id A document's id (requires :doc_rev)
    # @option args [String] :doc_rev A document's revision (requires :doc_id)
    # @option args [Hash] :options Extra options (refer to the official doc).
    # @return [Promise<Hash>]
    def remove(args = {})
      doc     = args[:doc]
      doc_id  = args[:doc_id]
      doc_rev = args[:doc_rev]
      options = args[:options]

      %x{
        var pouchPromise;
        if (doc) {
          pouchPromise = #{@native}.remove(#{doc.to_n}, #{options.to_n})
        } else {
          pouchPromise = #{@native}.remove(doc_id, doc_rev, #{options.to_n})
        }
      }

      as_opal_promise(`pouchPromise`)
    end

    # Creates or updates a document. When updating a document, its _id and _rev
    # can either be in `doc` or passed explicitly as :doc_id and :doc_rev.
    #
    # @param doc [Hash] The contents to create or update
    # @param args [Hash] Optional arguments
    # @option args [String] :doc_id A document's id (requires :doc_rev)
    # @option args [String] :doc_rev A document's rev (requires :id)
    # @option args [Hash] :options Extra options (refer to the official doc)
    # @return [Promise<Hash>]
    def put(doc, args = {})
      doc_id  = args[:doc_id]
      doc_rev = args[:doc_rev]
      options = args[:options]

      as_opal_promise(`#{@native}.put(#{doc.to_n}, doc_id, doc_rev, #{options.to_n})`)
    end

    # Creates a document, generating its id in the process. It's better to
    # always use `put` with an explicit id in order to avoid PouchDB's very long
    # Strings and to take advantage of its sorting of keys when using `all_docs`.
    #
    # @param doc [Hash] The contents to use when creating
    # @param options [Hash] Extra options (refer to the official doc)
    # @return [Promise<Hash>]
    def post(doc, options = {})
      as_opal_promise(`#{@native}.post(#{doc.to_n}, #{options.to_n})`)
    end

    # Retrieves a document from the database.
    #
    # @param doc_id [String] A document's id
    # @param options [Hash] Optional arguments. All default to `false`
    # @option options [String] :rev Fetch a specific revision. Defaults to
    #   winning revision
    # @option options [Boolean] :revs Include revision history with the document
    # @option options [Boolean] :revs_info Include a list of revisions, and
    #   their availability
    # @option options [String, Array<String>] :open_revs Fetch all leaf
    #   revisions if open_revs="all" or fetch all leaf revisions specified
    #   in open_revs array. Leaves will be returned in the same order as
    #   specified in input array
    # @option options [Boolean] :conflicts If specified, conflicting leaf
    #   revisions will be attached in _conflicts array
    # @option options [Boolean] :attachments Include attachment data
    # @option options [Hash] :ajax Refer to the official doc
    # @return [Promise<Hash>]
    def get(doc_id, options = {})
      as_opal_promise(`#{@native}.get(doc_id, #{options.to_n})`)
    end

    # Creates, updates or deletes multiple documents. If you omit an _id in one
    # of the documents, a new document will be created with a generated id; if
    # you pass in both an _id and _rev, it will be updated; if you add
    # `_deleted: true`, it will be removed.
    #
    # @param docs [Array<Hash>] an Array of documents
    # @param options [Hash] optional arguments
    def bulk_docs(docs, options = {})
      as_opal_promise(`#{@native}.bulkDocs(#{docs.to_n}, #{options.to_n})`,
                      &ARRAY_CONVERSION)
    end

    # Fetches multiple documents in bulk, indexing and sorting them by their
    # _ids. Deleted documents are only included if `options.keys` is specified.
    # All options are `false` unless otherwise specified.
    #
    # @param options [Hash] optional arguments
    # @option options [Boolean] include_docs include the document itself in
    #   each row in the `doc` field. Otherwise by default you only get the
    #   _id and rev properties.
    # @option options [Boolean] conflicts Include conflict information in
    #   the `_conflicts` field of a doc (only if `include_docs` is `true`)
    # @option options [Boolean] attachments Include attachment data as
    #   base64-encoded string (only if `include_docs` is `true`)
    # @option options [String] startkey Used in conjuction with `endkey`.
    #   Get documents with IDs in a certain range
    # @option options [String] endkey Used in conjuction with `startkey`.
    #   Get documents with IDs in a certain range
    # @option options [Boolean] inclusive_end Include documents having an
    #   ID equal to the given `options.endkey` (default: `true`)
    # @option options [Fixnum] limit Maximum number of documents to return
    # @option options [Fixnum] skip Number of documents to skip before
    #   returning (warning: poor performance on IndexedDB/LevelDB)
    # @option options [Boolean] descending Reverse the order of the output
    #   documents
    # @option options [String] key Only return documents with IDs matching
    #   this key
    # @option options [Array<String>] keys Keys to be fetched in a single
    #   shot. Neither `startkey` nor `endkey` can be specified with this
    #   option; the rows returned are in the same order as the supplied
    #   `keys` Array; the row for a deleted document will have the revision
    #   ID of the deletion, and an extra `deleted: true` in the `value`
    #   key; the row for a nonexistent document will just contain an
    #   `"error"` key with the value `"not_found"`. For details, see the
    #   CouchDB query options documentation.
    # @return [Promise]
    def all_docs(options = {})
      as_opal_promise(`#{@native}.allDocs(#{options.to_n})`) { |response|
        AllDocuments.new(response)
      }
    end

    # A list of changes made to documents in the database, in the order they
    # were made. It returns an object with the method `cancel()`, which you call
    # if you don't want to listen to new changes anymore.
    #
    # It is an EventEmitter and will emit a 'change' event on each document
    # change, a 'complete' event when all the changes have been processed, and
    # an 'error' event when an error occurs. In addition to the 'change' event,
    # any change will also emit a 'create', 'update', or 'delete' event.
    #
    # @param options [Hash] optional arguments
    # @option options [Boolean] include_docs Include the associated document
    #   with each change
    # @option options [Boolean] conflicts Include conflict information in
    #   the `_conflicts` field of a doc (only if `include_docs` is `true`)
    # @option options [Boolean] attachments Include attachment data as
    #   base64-encoded string (only if `include_docs` is `true`)
    # @option options [Boolean] descending Reverse the order of the output
    #   documents
    # @option options [String,Fixnum] since Start the results from the change
    #   immediately after the given sequence number. You can also pass
    #   'now' if you want only new changes (depends on `live: true` )
    # @option options [Fixnum] timeout The request timeout, in milliseconds
    # @option options [Fixnum] limit Limit the numbers of results to this
    #   number
    # @option options [Array<String>] Only shows changes for docs with these
    #   ids
    # @option options [String] filter Reference a filter function from a design
    #   document to selectively get updates. To use a view function, pass in
    #   `_view` and provide a reference to that function with the `view` key
    # @option options [Hash] query_params Properties to pass to the filter
    #   function (e.g.: { foo: "bar" }, where "bar" will be available in the
    #   filter function as `params.query.foo`. To have access to the params,
    #   define your function as receiving a second argument
    # @option options [String] view Specify a view function (e.g.
    #   "design_doc_name/view_name") to act as a filter. Documents counted
    #   as "passed" for a view filter if a map function emits at least one
    #   record of them (`options.filter` must be set to `"_view"`)
    # @option options [Boolean] returnDocs Available for non-http databases
    #   only, and defaults to `true`. Passing `false` prevents the changes
    #   feed from keeping all the documents in memory -- in other words,
    #   complete always has an empty results array, and the `change` event
    #   is the only way to get the event. Useful for large change sets
    #   where otherwise you would run out of memory
    # @option options [Fixnum] batch_size Only available for http databases,
    #   this configures how many changes to fetch at a time. Increasing this
    #   can reduce the number of requests made. Default is 25.
    # @option options [String] style Specifies how many revisions are returned
    #   in the changes array. The default, `"main_only"`, will only return
    #   the current "winning" revision; `"all_docs"` will return all leaf
    #   revisions (including conflicts and deleted former conflicts). Most
    #   likely you won't need this unless you are writing a replicator.
    # @return [EventEmitter]
    def changes(options = {})
      EventEmitter.new(`#{@native}.changes(#{options.to_n})`)
    end

    def replicate
      Replication.new(@native)
    end

    def sync(other)
      EventEmitter.new(`#{@native}.sync(#{database_as_string(other)})`)
    end

    # Get information about a database.
    #
    # @return [Promise]
    def info
      as_opal_promise(`#{@native}.info()`)
    end

    # Cleans up any stale map/reduce indexes.
    #
    # As design docs are deleted or modified, their associated index files (in
    # CouchDB) or companion databases (in local PouchDBs) continue to take up
    # space on disk. view_cleanup removes these unnecessary index files.
    #
    # @return [Promise]
    def view_cleanup
      as_opal_promise(`#{@native}.viewCleanup()`)
    end

    # Triggers a compaction operation in the local or remote database. This
    # reduces the database’s size by removing unused and old data, namely
    # non-leaf revisions and attachments that are no longer referenced by those
    # revisions. Note that this is a separate operation from view_cleanup.
    #
    # For remote databases, PouchDB checks the compaction status at regular
    # intervals and fires the callback (or resolves the promise) upon
    # completion. Consult the compaction section of CouchDB’s maintenance
    # documentation for more details.
    #
    # Also see auto-compaction, which runs compaction automatically (local
    # databases only).
    #
    # @param options [Hash] optional arguments
    # @option options [Fixnum] interval  Number of milliseconds to wait
    #   before asking again if compaction is already done. Defaults to 200.
    #   (Only applies to remote databases.)
    def compact(options = {})
      as_opal_promise(`#{@native}.compact(#{options.to_n})`)
    end
  end
end

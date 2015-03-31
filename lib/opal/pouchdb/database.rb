module PouchDB
  class Database
    include Native

    DEFAULT_HANDLER = ->(response) { Native(response) }

    def initialize(options = {})
      @name = options.fetch(:name)
      super `new PouchDB(#{options.to_n})`
    end

    attr_reader :name

    # TODO: Pass options on.
    def destroy(options = {})
      as_opal_promise(`#{@native}.destroy()`)
    end

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

    def put(doc, args = {})
      doc_id  = args[:id]
      doc_rev = args[:rev]
      options = args[:options]

      as_opal_promise(`#{@native}.put(#{doc.to_n}, doc_id, doc_rev, #{options.to_n})`)
    end

    def post(doc, options = {})
      as_opal_promise(`#{@native}.post(#{doc.to_n}, #{options.to_n})`)
    end

    def get(doc_id, options = {})
      as_opal_promise(`#{@native}.get(doc_id, #{options.to_n})`)
    end

    def bulk_docs(docs, options = {})
      as_opal_promise(`#{@native}.bulkDocs(#{docs.to_n}, #{options.to_n})`) { |resp|
        resp.map { |o| Native(o) }
      }
    end

    private

    def as_opal_promise(pouch_promise_n, &response_handler)
      pouch_promise = Native(pouch_promise_n)
      handler       = response_handler || DEFAULT_HANDLER
      promise       = Promise.new

      pouch_promise
        .then(-> (response) do promise.resolve(handler.call(response)) end)
        .catch(-> (error) do promise.reject(error) end)

      promise
    end
  end
end

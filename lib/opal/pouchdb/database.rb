module PouchDB
  class Database
    include Native

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

    def get(doc_id, options = {})
      as_opal_promise(`#{@native}.get(doc_id, #{options.to_n})`)
    end

    private

    def as_opal_promise(pouch_promise_n)
      pouch_promise = Native(pouch_promise_n)

      promise = Promise.new

      pouch_promise
        .then(-> (response) { promise.resolve(Native(response)) })
        .catch(-> (error) { promise.reject(error) })

      promise
    end
  end
end

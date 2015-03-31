module PouchDB
  class Database
    include Native

    def initialize(options = {})
      @name = options.fetch(:name)
      super `new PouchDB(#{options.to_n})`
    end

    attr_reader :name

    def destroy(options = {})
      promise = Promise.new
      %x{
        #{@native}.destroy().then(function(response) {
          #{promise.resolve(Native(`response`))}
        }).catch(function(error) {
          #{promise.reject(`error`)}
        })
      }

      promise
    end

    def remove(args = {})
      doc     = args[:doc]
      doc_id  = args[:doc_id]
      doc_rev = args[:doc_rev]
      options = args[:options]

      promise = Promise.new

      %x{
        var pouchPromise;
        if (doc) {
          pouchPromise = #{@native}.remove(#{doc.to_n}, #{options.to_n})
        } else {
          pouchPromise = #{@native}.remove(doc_id, doc_rev, #{options.to_n})
        }

        pouchPromise.then(function(response) {
          #{promise.resolve(Native(`response`))}
        }).catch(function(error) {
          #{promise.reject(`error`)}
        })
      }

      promise
    end

    def put(doc, args = {})
      doc_id  = args[:id]
      doc_rev = args[:rev]
      options = args[:options]

      promise = Promise.new

      %x{
        #{@native}.put(#{doc.to_n}, doc_id, doc_rev, #{options.to_n}).then(function(response) {
          #{promise.resolve(Native(`response`))}
        }).catch(function(error)  {
          #{promise.reject(`error`)}
        })
      }

      promise
    end

    def get(doc_id, options = {})
      promise = Promise.new

      %x{
        #{@native}.get(doc_id, #{options.to_n}).then(function(response) {
          #{promise.resolve(Native(`response`))}
        }).catch(function(error)  {
          #{promise.reject(`error`)}
        })
      }

      promise
    end
  end
end

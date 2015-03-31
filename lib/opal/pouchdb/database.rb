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

    def put(doc, doc_id = nil, doc_rev = nil, options = nil)
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

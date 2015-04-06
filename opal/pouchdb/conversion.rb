module PouchDB
  module Conversion
    OBJECT_CONVERSION = ->(response) {
      if (maybe_exception = Native(response)).is_a?(Exception)
        maybe_exception
      else
        Hash.new(response)
      end
    }
    ARRAY_CONVERSION = ->(response) { response.map { |o| OBJECT_CONVERSION.call(o) } }

    def as_opal_promise(pouch_promise_n, &response_handler)
      pouch_promise = Native(pouch_promise_n)
      handler       = response_handler || OBJECT_CONVERSION
      promise       = Promise.new

      pouch_promise
        .then(-> (response) do promise.resolve(handler.call(response)) end)
        .catch(-> (error) do promise.reject(error) end)

      promise
    end

    def database_as_string(db)
      db.is_a?(Database) ? db.name : db
    end
  end
end

module PouchDB
  class EventEmitter
    include Conversion

    def initialize(native_db, stream)
      @native_db = native_db
      @native    = stream
    end

    def on(event, &blk)
      %x{
        #{@native}.on(event, function(change) {
          #{blk.call(OBJECT_CONVERSION.call(`change`))}
        })
      }
    end

    def then
      as_opal_promise(`#{@native}`)
    end

    def cancel
      `#{@native}.cancel()`
    end
  end
end

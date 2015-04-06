module PouchDB
  class EventEmitter
    include Conversion

    def initialize(stream)
      @native    = stream
    end

    def on(event, &blk)
      %x{
        #{@native}.on(event, function(change) {
          #{blk.call(OBJECT_CONVERSION.call(`change`))}
        })
      }

      self
    end

    def then
      as_opal_promise(`#{@native}`)
    end

    def cancel
      `#{@native}.cancel()`
    end
  end
end

module PouchDB
  class EventEmitter
    include Conversion

    def initialize(stream)
      @native = stream
    end

    def on(event, conversion = OBJECT_CONVERSION, &blk)
      %x{
        var wrapper = function(o) {
          #{blk.call(conversion.call(`o`))}
        }

        blk.__pouch_wrapper = wrapper

        #{@native}.on(event, wrapper)
      }

      self
    end

    def remove_listener(event, conversion = OBJECT_CONVERSION, &blk)
      %x{
        if (blk.__pouch_wrapper) {
          #{@native}.removeListener(event, blk.__pouch_wrapper)
        }
      }
    end

    def remove_all_listeners(event)
      `#{@native}.removeAllListeners(event)`
    end

    def then
      as_opal_promise(`#{@native}`)
    end

    def cancel
      `#{@native}.cancel()`
    end
  end
end

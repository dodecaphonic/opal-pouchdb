module PouchDB
  class Row
    include Native

    def initialize(native_row)
      super native_row
    end

    native_reader :id, :key, :value

    def document
      Hash.new(`#{@native}.doc`)
    end
  end
end

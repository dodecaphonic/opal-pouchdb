module PouchDB
  class Replication
    include Conversion

    def initialize(native)
      @native = native
    end

    def to(db, options = {})
      EventEmitter.new(`#{@native}.replicate.to(#{database_as_string(db)}, #{options.to_n})`)
    end

    def from(db, options = {})
      EventEmitter.new(`#{@native}.replicate.from(#{database_as_string(db)}, #{options.to_n})`)
    end
  end
end

module PouchDB
  class Database
    include Native

    def initialize(options = {})
      super `new PouchDB(#{options.to_n})`
    end

    def destroy(ajax_options = nil, &block)
      puts "Calling destroy"
    end
  end
end

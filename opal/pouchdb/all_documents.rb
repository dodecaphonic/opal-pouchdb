module PouchDB
  class AllDocuments
    include Enumerable

    def initialize(results)
      @results = results
    end

    def offset
      `#{@results}.offset`
    end

    def total_rows
      `#{@results}.total_rows`
    end

    def size
      `#{@results}.rows.length`
    end

    alias_method :count, :size
    alias_method :length, :size

    def each
      `#{@results}.rows`.each do |r|
        yield Row.new(r)
      end
    end
  end
end

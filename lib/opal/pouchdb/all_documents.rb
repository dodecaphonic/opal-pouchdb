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

    alias_method :size, :total_rows
    alias_method :length, :total_rows
    alias_method :count, :total_rows

    def each
      rows = `#{@results}.rows`

      rows.each do |r|
        yield Native(r)
      end
    end
  end
end

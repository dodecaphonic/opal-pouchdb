require "spec_helper"

describe "PouchDB::Database#changes" do
  describe "changes" do
    async "calls a block when a 'change' event is emitted" do
      with_new_database do |db|
        db.post(name: "I Change Things")
        db.post(name: "I Change Things Too")

        stream = db.changes
        count  = 0
        stream.on "change" do count += 1 end

        delayed(1.2) do |p|
          p.resolve(count == 2)
        end.then do |c|
          async do
            expect(c).to be(true)
          end
        end
      end
    end
  end

  describe "cancellation" do
    async "calls a block when the 'complete' event is emitted" do
      with_new_database do |db|
        stream    = db.changes
        cancelled = false
        stream.on "complete" do cancelled = true end

        delayed(1) do |p|
          p.resolve(cancelled)
        end.then do |c|
          async do
            expect(c).to be(true)
          end
        end
      end
    end
  end

  describe "single-shot" do
    # TODO: Make this pass. I think I'm missing some important
    # point of the "Single-shot" mode.
    pending "calls a block with all the changes" do
      with_new_database do |db|
        db.post(classification: "Important Stuff")
        db.post(classification: "REALLY Important Stuff")

        db.changes(limit: 1, since: 0).then do |cs|
          async do
            expect(cs).to eq(1)
          end
        end
      end
    end
  end

  async "passes options along" do
    with_new_database do |db|
      db.post(name: "Ishmael")
      db.post(name: "Fishmael")

      changes = []
      db.changes(include_docs: true).on "change" do |c|
        changes << c
      end

      delayed(1.2) do |p|
        p.resolve(changes)
      end.then do |c|
        async do
          expect(c.size).to eq(2)
          expect(c.first["doc"]["name"]).to eq("Ishmael")
          expect(c.last["doc"]["name"]).to eq("Fishmael")
        end
      end
    end
  end

  def delayed(delay_by, &blk)
    promise = Promise.new
    $global.setTimeout(-> { blk.call(promise) }, delay_by * 1000)
    promise
  end
end

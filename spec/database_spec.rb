require "spec_helper"
require "securerandom"

describe PouchDB::Database do
  let(:docs) {
    [
      { name: "Banana", color: "yellow" },
      { name: "Apple", color: "red" },
      { name: "Green Apple", color: "green" }
    ]
  }

  let(:docs_with_ids) {
    docs.map { |d|
      d.merge(_id: d[:name].downcase.gsub(/\s+/, "-"))
    }
  }

  let(:sorted_ids) {
    docs_with_ids.map { |d| d[:_id] }.sort
  }

  describe "#initialize" do
    it "requires a name" do
      expect { PouchDB::Database.new }.to raise_error(KeyError)
    end
  end

  describe "#destroy" do
    let(:database_name) { "throaway_test_database" }

    async "calls the returned Promise's success handler" do
      with_new_database do |db|
        db.destroy.then do |response|
          run_async do
            expect(response["ok"]).to be(true)
          end
        end
      end
    end
  end

  describe "#put" do
    async "creating a new Document calls the returned Promise's success handler" do
      with_new_database do |db|
        promise = db.put(docs_with_ids.first)

        promise.then do |response|
          run_async do
            expect(response).not_to be_nil
            expect(response["rev"]).not_to be_nil
            expect(response["id"]).to eq("banana")
          end
        end
      end
    end

    async "updating an existing Document calls the returned Promise's success handler" do
      with_new_database do |db|
        db.put(docs_with_ids.first).then do |created|
          update = { name: "Bananananas" }

          db.put(update, id: created["id"], rev: created["rev"]).then do |updated|
            run_async do
              expect(updated["rev"]).not_to eq(created["rev"])
            end
          end
        end
      end
    end

    async "calls the returned Promise's error handler" do
      with_new_database(false) do |db|
        db.put(docs.first).fail do |error|
          run_async do
            expect(error.message).to match(/_id is required/)
          end
        end
      end
    end
  end

  describe "#post" do
    async "posting new Document generates an id" do
      with_new_database do |db|
        promise = db.post(docs.first)

        promise.then do |response|
          run_async do
            expect(response["rev"]).not_to be_nil
            expect(response["id"]).not_to be_nil
          end
        end
      end
    end
  end

  describe "#bulk_docs" do
    async "generates ids if Documents don't have them" do
      with_new_database do |db|
        db.bulk_docs(docs).then do |response|
          run_async do
            expect(response.size).to eq(3)
            expect(response.all? { |r| r["ok"] }).to be(true)
            expect(response.map { |r| r["id"] }.none?(&:empty?)).to be(true)
          end
        end
      end
    end

    async "keeps passed-in ids if Documents have them" do
      with_new_database do |db|
        db.bulk_docs(docs_with_ids).then do |response|
          run_async do
            expect(response.map { |r| r["id"] }.sort).to eq(sorted_ids)
          end
        end
      end
    end

    async "updates sets of Documents" do
      with_new_database do |db|
        by_id = Hash[docs_with_ids.map { |d| [d[:_id], d] }]

        db.bulk_docs(docs_with_ids).then do |created|
          new_versions = created.map { |r|
            d = by_id[r["id"]]
            d.merge(_id: r["id"], _rev: r["rev"], name: d[:name].reverse)
          }

          created_by_id = Hash[created.map { |c| [c[:id], c] }]

          db.bulk_docs(new_versions).then do |updated|
            run_async do
              updated.each do |ud|
                cd = created_by_id[ud["id"]]
                expect(ud["rev"]).not_to eq(cd["rev"])
              end
            end
          end
        end
      end
    end

    async "mixes errors with successes (non-transactional)" do
      with_new_database do |db|
        db.put(docs_with_ids.first).then do
          db.bulk_docs(docs_with_ids)
        end.then do |response|
          run_async do
            errors = response.select { |r| r.is_a?(Exception) }
            ok     = response - errors

            expect(ok.size).to eq(2)
            expect(errors.size).to eq(1)
            expect(errors.first.message).to match(/conflict/)
          end
        end
      end
    end
  end

  describe "#get" do
    async "calls the returned Promise's success handler with a Document" do
      with_new_database do |db|
        db.put(_id: "magic_object", contents: "It's Magic").then do
          db.get("magic_object")
        end.then do |doc|
          run_async do
            expect(doc["_id"]).to eq("magic_object")
            expect(doc["contents"]).to eq("It's Magic")
          end
        end
      end
    end

    async "correctly serializes/deserializes nested Hashes" do
      with_new_database do |db|
        promise = db.put(_id: "nasty_nested",
                         contents: { foo: { bar: { baz: 1 } } })

        promise.then do
          db.get("nasty_nested")
        end.then do |document|
          run_async do
            expect(document["contents"]["foo"]["bar"]["baz"]).to eq(1)
          end
        end
      end
    end
  end

  describe "#all_docs" do
    async "fetches every Document by default" do
      with_new_database do |db|
        db.bulk_docs(docs_with_ids).then do
          db.all_docs
        end.then do |rows|
          run_async do
            expect(rows.size).to eq(sorted_ids.size)
            expect(rows.map(&:id).sort).to eq(sorted_ids)
            expect(rows.first.document).to eq({})
          end
        end
      end
    end

    # dodecaphonic: This is non-exhaustive. I just want to check if
    # passing options actually goes through.
    describe "passing options along" do
      async "allows for full Documents to come with a Row" do
        with_new_database do |db|
          db.bulk_docs(docs_with_ids).then do
            db.all_docs(include_docs: true)
          end.then do |rows|
            run_async do
              expect(rows.first.document["name"]).not_to be_empty
            end
          end
        end
      end

      async "can limit the number of Rows to return" do
        with_new_database do |db|
          db.bulk_docs(docs_with_ids).then do
            db.all_docs(key: "banana").then do |rows|
              run_async do
                expect(rows.size).to eq(1)
              end
            end
          end
        end
      end
    end
  end

  describe "#remove" do
    let(:doc) { docs_with_ids.first }

    describe "with a Document containing an _id and _rev" do
      async "works correctly" do
        with_new_database do |db|
          db.put(doc).then do |created|
            run_async do
              to_remove = { _id: created["id"], _rev: created["rev"] }
              db.remove(doc: to_remove)
            end
          end
        end.then do |removed|
          run_async do
            expect(removed["ok"]).to be(true)
          end
        end
      end

      async "fails if _id is missing" do
        with_new_database(false) do |db|
          db.put(doc).then do |created|
            run_async do
              to_remove = { _rev: created["rev"] }
              db.remove(doc: to_remove)
            end
          end
        end.fail do |error|
          run_async do
            expect(error.message).to match(/missing/)
          end
        end
      end

      async "fails if _rev is missing" do
        with_new_database(false) do |db|
          db.put(doc).then do |created|
            run_async do
              to_remove = { _id: created["id"] }
              db.remove(doc: to_remove)
            end
          end
        end.fail do |error|
          run_async do
            expect(error.message).to match(/missing/)
          end
        end
      end
    end

    describe "passing its _id and _rev explicitly" do
      async "works correctly" do
        with_new_database do |db|
          db.put(doc).then do |created|
            run_async do
              db.remove(doc_id: created["id"], doc_rev: created["rev"])
            end
          end
        end.then do |removed|
          run_async do
            expect(removed.ok).to be(true)
          end
        end
      end

      async "fails if _id is missing" do
        with_new_database(false) do |db|
          db.put(doc).then do |created|
            run_async do
              db.remove(doc_rev: created["rev"])
            end
          end
        end.fail do |error|
          run_async do
            expect(error.message).to match(/missing/)
          end
        end
      end

      async "fails if _rev is missing" do
        with_new_database(false) do |db|
          db.put(doc).then do |created|
            run_async do
              db.remove(doc_id: created["id"])
            end
          end
        end.fail do |error|
          run_async do
            expect(error.message).to match(/missing/)
          end
        end
      end
    end
  end
end

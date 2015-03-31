require "spec_helper"
require "securerandom"

describe PouchDB::Database do
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
            expect(response.ok).to be(true)
          end
        end
      end
    end
  end

  describe "#put" do
    let(:default_object) {
      { _id: "foo", contents: "Baz" }
    }

    async "creating a new Document calls the returned Promise's success handler" do
      with_new_database do |db|
        promise = db.put(_id: "bar", contents: "Fudge")

        promise.then do |response|
          run_async do
            expect(response).not_to be_nil
            expect(response.rev).not_to be_nil
            expect(response.id).to eq("bar")
          end
        end
      end
    end

    async "updating an existing Document calls the returned Promise's success handler" do
      with_new_database do |db|
        db.put(_id: "awesome-unique", contents: "Chocolate").then do |created|
          doc = { contents: "Bananas" }
          db.put(doc, id: created.id, rev: created.rev).then do |updated|
            run_async do
              expect(updated.rev).not_to eq(created.rev)
            end
          end
        end
      end
    end

    async "calls the returned Promise's error handler" do
      with_new_database(false) do |db|
        db.put(contents: "No id means bad news").fail do |error|
          run_async do
            expect(error.message).to match(/_id is required/)
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
            expect(doc._id).to eq("magic_object")
            expect(doc.contents).to eq("It's Magic")
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
            expect(document.contents.foo.bar.baz).to eq(1)
          end
        end
      end
    end
  end

  describe "removing Documents" do
    let(:doc) {
      { _id: "new-id-new-life", contents: "Pears" }
    }

    describe "with a Document containing an _id and _rev" do
      async "works correctly" do
        with_new_database do |db|
          db.put(doc).then do |created|
            run_async do
              to_remove = { _id: created.id, _rev: created.rev }
              db.remove(doc: to_remove)
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
              to_remove = { _rev: created.rev }
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
              to_remove = { _id: created.id }
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
              db.remove(doc_id: created.id, doc_rev: created.rev)
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
              db.remove(doc_rev: created.rev)
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
              db.remove(doc_id: created.id)
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

  def with_new_database(add_failure_handler = true)
    database_name = "test_opal_pouchdb_database-#{rand(1337)}"
    promise = yield PouchDB::Database.new(name: database_name)

    if add_failure_handler
      promise = promise.fail do |error|
        run_async do
          fail error
        end
      end
    end

    promise.always do
      destroy_database(database_name)
    end
  end

  def destroy_database(name)
    %x{
      var db = new PouchDB(name);
      db.destroy()
    }
  end
end

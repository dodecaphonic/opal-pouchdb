require "spec_helper"

describe PouchDB::Database do
  describe "#initialize" do
    it "requires a name" do
      expect { PouchDB::Database.new }.to raise_error(KeyError)
    end
  end

  describe "#destroy" do
    let(:database_name) { "throaway_test_database" }

    async "calls the returned Promise's success handler" do
      with_new_database do |name, db|
        db.destroy.then do |response|
          run_async do
            expect(response[:ok]).to be(true)
          end
        end.fail do |error|
          run_async do
            fail error
          end
        end
      end
    end
  end

  describe "#put" do
    let(:default_object) {
      { _id: "foo", contents: "Baz" }
    }

    async "calls the returned Promise's success handler" do
      with_new_database do |name, db|
        promise = db.put(_id: "bar", contents: "Fudge")

        promise.then do |response|
          run_async do
            expect(response).not_to be_nil
            expect(response[:rev]).not_to be_nil
            expect(response[:id]).to eq("bar")
          end
        end.fail do |error|
          run_async do
            fail error
          end
        end.always do
          destroy_database(name)
        end
      end
    end

    async "calls the returned Promise's error handler" do
      with_new_database do |name, db|
        db.put(contents: "No id means bad news").fail do |error|
          run_async do
            expect(error.message).to match(/_id is required/)
          end
        end.always do
          destroy_database(name)
        end
      end
    end
  end

  describe "#get" do
    async "calls the returned Promise's success handler with a Document" do
      with_new_database do |name, db|
        db.put(_id: "magic_object", contents: "It's Magic").then do
          db.get("magic_object")
        end.then do |doc|
          run_async do
            expect(doc[:_id]).to eq("magic_object")
            expect(doc[:contents]).to eq("It's Magic")
          end
        end.fail do |error|
          run_async do
            fail error
          end
        end.finally do
          destroy_database(name)
        end
      end
    end

    async "correctly serializes/deserializes nested Hashes" do
      with_new_database do |name, db|
        promise = db.put(_id: "nasty_nested",
                         contents: { foo: { bar: { baz: 1 } } })

        promise.then do
          db.get("nasty_nested")
        end.then do |document|
          run_async do
            expect(document[:contents][:foo][:bar][:baz]).to eq(1)
          end
        end.fail do |error|
          run_async do
            $global.console.log "FAILED HERE", error
            fail error
          end
        end.always do
          destroy_database(name)
        end
      end
    end
  end

  def with_new_database
    database_name = "test_opal_pouchdb_database-#{Time.now.to_i}"
    yield database_name, PouchDB::Database.new(name: database_name)
  end

  def destroy_database(name)
    %x{
      var db = new PouchDB(name);
      db.destroy()
    }
  end
end

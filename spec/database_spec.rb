require "spec_helper"

describe PouchDB::Database do
  let(:database_name) { "test_opal_pouchdb" }

  subject { PouchDB::Database.new(name: database_name) }

  after do
    db_name = database_name

    %x{
      var db = new PouchDB(db_name);
      db.destroy()
    }
  end

  describe "#initialize" do
    it "requires a name" do
      expect { PouchDB::Database.new }.to raise_error(KeyError)
    end
  end

  describe "#destroy" do
    let(:database_name) { "throaway_test_database" }

    it "returns a Promise" do
      expect(subject.destroy).to be_a(Promise)
    end

    async "calls the returned Promise's success handler" do
      subject.destroy.then do |response|
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

  describe "#put" do
    let(:default_object) {
      { _id: "foo", contents: "Baz" }
    }

    it "returns a Promise" do
      expect(put_object(default_object)).to be_a(Promise)
    end

    async "calls the returned Promise's success handler" do
      promise = put_object(_id: "bar", contents: "Fudge")

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
      end
    end

    async "calls the returned Promise's error handler" do
      put_object(contents: "No id means bad news").fail do |error|
        run_async do
          expect(error.message).to match(/_id is required/)
        end
      end
    end
  end

  describe "#get" do
    it "returns a Promise" do
      expect(subject.get("an_id")).to be_a(Promise)
    end

    async "calls the returned Promise's success handler with a Document" do
      database = PouchDB::Database.new(name: "asdfjaslfjlskalas-#{Time.now.to_i}")
      database.put(_id: "magic_object", contents: "It's Magic").then do
        database.get("magic_object")
      end.then do |doc|
        run_async do
          expect(doc[:_id]).to eq("magic_object")
          expect(doc[:contents]).to eq("It's Magic")
        end
      end.fail do |error|
        run_async do
          fail error
        end
      end
    end

    async "correctly serializes/deserializes nested Hashes" do
      promise = put_object(_id: "nasty_nested",
                           contents: { foo: { bar: { baz: 1 } } })

      promise.then do
        subject.get("nasty_nested")
      end.then do |document|
        run_async do
          expect(document[:contents][:foo][:bar][:baz]).to eq(1)
        end
      end.fail do |error|
        run_async do
          fail error
        end
      end
    end
  end

  def put_object(o)
    subject.put(o)
  end
end

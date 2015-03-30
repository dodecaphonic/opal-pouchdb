require "spec_helper"

describe PouchDB::Database do
  let(:database_name) { "test_opal_pouchdb" }

  subject { PouchDB.new(name: database_name) }

  describe "creating a database" do
    it "requires a name" do
      expect { PouchDB.new }.to raise_error(ArgumentError)
    end
  end
end

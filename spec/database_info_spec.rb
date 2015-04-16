require "spec_helper"

describe "PouchDB::Database#info" do
  async "fetches information" do
    with_new_database do |db|
      db.info.then do |info|
        async do
          expect(info["db_name"]).to eq(db.name)
        end
      end
    end
  end
end

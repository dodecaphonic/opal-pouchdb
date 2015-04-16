require "spec_helper"

describe "PouchDB::Database#compaction" do
  it "returns an 'ok' response" do
    with_new_database do |db|
      db.compact.then do |response|
        async do
          expect(response["ok"]).to eq("true")
        end
      end
    end
  end
end

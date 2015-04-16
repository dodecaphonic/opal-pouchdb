require "spec_helper"

describe "PouchDB::Database#revs_diff" do
  let(:shas) {
    ["1-b2e54331db828310f3c772d6e042ac9c", "2-3a24009a9525bde9e4bfa8a99046b00d"]
  }

  let(:diff) {
    {
      "magic-document" => shas
    }
  }

  it "returns a Hash of missing revisions" do
    with_new_database do |db|
      db.revs_diff(diff).then do |missing|
        async do
          expect(missing["magic-document"]["missing"]).to eq(shas)
        end
      end
    end
  end
end

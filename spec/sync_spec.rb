require "spec_helper"

describe "Synchronization" do
  let(:name) { "I'm a big boy now" }

  describe "PouchDB.sync" do
    async "performs bidirectional sync passing Strings" do
      with_new_database do |source|
        with_new_database do |target|
          stream = PouchDB.sync(source.name, target.name)

          source.put(_id: "my-calvins", name: name)
          target.put(_id: "your-calvins", name: name)

          delayed(1.0) do |p|
            source.get("your-calvins").then do |d0|
              target.get("my-calvins").then do |d1|
                p.resolve([d0, d1])
              end
            end
          end.then do |d0, d1|
            async do
              expect(d0["_id"]).to eq("your-calvins")
              expect(d1["_id"]).to eq("my-calvins")
            end
          end
        end
      end
    end

    async "performs bidirectional sync passing Databases" do
      with_new_database do |source|
        with_new_database do |target|
          stream = PouchDB.sync(source, target)

          source.put(_id: "my-calvins", name: name)
          target.put(_id: "your-calvins", name: name)

          delayed(1.0) do |p|
            source.get("your-calvins").then do |d0|
              target.get("my-calvins").then do |d1|
                p.resolve([d0, d1])
              end
            end
          end.then do |d0, d1|
            async do
              expect(d0["_id"]).to eq("your-calvins")
              expect(d1["_id"]).to eq("my-calvins")
            end
          end
        end
      end
    end
  end

  describe "PouchDB::Database#sync" do
    async "performs bidirectional sync" do
      with_new_database do |source|
        with_new_database do |target|
          stream = source.sync(target)

          source.put(_id: "my-calvins", name: name)
          target.put(_id: "your-calvins", name: name)

          delayed(1.0) do |p|
            source.get("your-calvins").then do |d0|
              target.get("my-calvins").then do |d1|
                p.resolve([d0, d1])
              end
            end
          end.then do |d0, d1|
            async do
              expect(d0["_id"]).to eq("your-calvins")
              expect(d1["_id"]).to eq("my-calvins")
            end
          end
        end
      end
    end

  end
end

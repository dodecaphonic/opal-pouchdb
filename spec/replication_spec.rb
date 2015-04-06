require "spec_helper"

describe "Replication" do
  let(:name) { "I'm a big boy now" }

  describe "PouchDB.replicate" do
    async "replicates passing names as Strings" do
      with_new_database do |source|
        with_new_database do |target|
          stream = PouchDB.replicate(source.name, target.name)

          synced = false

          stream.on "change" do
            target.get("my-calvins").then do |d|
              synced = true
            end
          end

          source.put(_id: "my-calvins", name: name)

          delayed(1.0) do |p|
            p.resolve(synced)
          end.then do |s|
            target.get("my-calvins").then do |doc|
              async do
                expect(doc["name"]).to eq(name)
              end
            end
          end
        end
      end
    end

    async "replicates passing Databases" do
      with_new_database do |source|
        with_new_database do |target|
          stream = PouchDB.replicate(source, target)

          synced = false

          stream.on "change" do
            target.get("my-calvins").then do |d|
              synced = true
            end
          end

          source.put(_id: "my-calvins", name: name)

          delayed(1.0) do |p|
            p.resolve(synced)
          end.then do |s|
            target.get("my-calvins").then do |doc|
              async do
                expect(doc["name"]).to eq(name)
              end
            end
          end
        end
      end
    end
  end

  describe "PouchDB::Database#replicate" do
    async "replicates to remote" do
      with_new_database do |source|
        with_new_database do |target|
          stream = source.replicate.to(target.name)

          source.put(_id: "my-calvins", name: name)

          delayed(1.0) do |p|
            p.resolve
          end.then do |s|
            target.get("my-calvins").then do |doc|
              async do
                expect(doc["name"]).to eq(name)
              end
            end
          end.always do
            stream.cancel
          end
        end
      end
    end

    async "replicats from remote" do
      with_new_database do |source|
        with_new_database do |target|
          stream = source.replicate.from(target.name)

          target.put(_id: "my-calvins", name: name)

          delayed(1.0) do |p|
            p.resolve
          end.then do |s|
            source.get("my-calvins").then do |doc|
              async do
                expect(doc["name"]).to eq(name)
              end
            end
          end.always do
            stream.cancel
          end
        end
      end
    end
  end
end

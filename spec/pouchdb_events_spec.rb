require "spec_helper"

describe "PouchDB Events" do
  after do
    `PouchDB.removeAllListeners("created")`
    `PouchDB.removeAllListeners("destroyed")`
  end

  async "calls back on create events" do
    PouchDB.on "created" do |db_name|
      async do
        expect(db_name).not_to be_nil
      end
    end

    create_and_destroy_database
  end

  async "calls back on destroy events" do
    PouchDB.on "destroyed" do |db_name|
      async do
        expect(db_name).not_to be_nil
      end
    end

    create_and_destroy_database
  end

  async "allows specific listeners of an event to be removed" do
    db_name = random_database_name

    ever_called = false
    callback = ->(dbn) do
      # This looks super weird, but it's here to ensure other
      # async tests don't influence this one. If it's been set
      # to true, we don't need to touch it again.
      unless ever_called
        ever_called = dbn == db_name
      end
    end

    PouchDB.on "created", &callback
    PouchDB.remove_listener "created", &callback

    delayed(1) do |p|
      p.resolve(!ever_called)
    end.then do |never_called|
      async do
        expect(never_called).to be(true)
      end
    end

    create_and_destroy_database db_name
  end

  async "allows all listeners of an event to be removed" do
    db_name = random_database_name

    ever_called = false
    PouchDB.on "created" do |dbn|
      # This looks super weird, but it's here to ensure other
      # async tests don't influence this one. If it's been set
      # to true, we don't need to touch it again.
      unless ever_called
        ever_called = dbn == db_name
      end
    end

    PouchDB.remove_all_listeners "created"

    delayed(1) do |p|
      p.resolve(!ever_called)
    end.then do |never_called|
      async do
        expect(never_called).to be(true)
      end
    end

    create_and_destroy_database db_name
  end

  def create_and_destroy_database(db_name = random_database_name)
    db = PouchDB::Database.new(name: db_name)
    db.destroy
  end
end

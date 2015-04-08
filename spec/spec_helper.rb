require "opal-rspec"
require "opal-pouchdb"

def with_new_database(add_failure_handler = true)
  database_name = "test_opal_pouchdb_database-#{rand(1337)}-#{rand(7331)}"
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

def delayed(delay_by, &blk)
  promise = Promise.new
  $global.setTimeout(-> { blk.call(promise) }, delay_by * 1000)
  promise
end

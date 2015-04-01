# opal-pouchdb: A PouchDB Wrapper for Opal

[![Build Status](https://travis-ci.org/dodecaphonic/opal-pouchdb.svg?branch=master)](https://travis-ci.org/dodecaphonic/opal-pouchdb)
[![Code Climate](https://codeclimate.com/github/dodecaphonic/opal-pouchdb/badges/gpa.svg)](https://codeclimate.com/github/dodecaphonic/opal-pouchdb)

opal-pouchdb allows [PouchDB][pouchdb] databases to be used with a nice Ruby API.

## Usage

Basic usage follows [PouchDB's API][pouchdb-api] very closely. The major difference is that, in JavaScript, a developer may decide if she wishes get the results of her interactions with the database via callbacks or promises. In opal-pouchdb, everything returns an [Opal Promise][opal-promise], allowing your async code to be as composable as that abstraction allows.

``` ruby
db = PouchDB::Database.new("my_database")

db.put(_id: "doc-1", summary: "Awesome", text: "Cake").then
  db.get("doc-1")
end.then do |db_record|
  puts db_record # => { "_id" => "doc-1", "_rev" => "some-large-string", "summary" => "Awesome", "text" => "Cake" }
end
```

Every single CRUD operation is supported right now:

- put
- post
- get
- delete
- all_docs
- bulk_docs

## TODO

- Sync
- Replication
- Attachments
- Querying
- Views
- Database info
- Compaction
- Revision diff
- Events
- Plugins
- Debug mode

[pouchdb]: http://pouchdb.com
[pouchdb-api]: http://pouchdb.com/api.html
[opal-promise]: http://opalrb.org/docs/promises/

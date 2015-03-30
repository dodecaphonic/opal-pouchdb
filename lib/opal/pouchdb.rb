if RUBY_ENGINE == "opal"
  require "native"
  require "opal/pouchdb/database"
else
  require "opal"
  require "opal/pouchdb/version"
end

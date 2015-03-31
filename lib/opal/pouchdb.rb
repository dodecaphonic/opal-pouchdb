if RUBY_ENGINE == "opal"
  require "native"
  require "promise"

  require "opal/pouchdb/database"
  require "opal/pouchdb/all_documents"
  require "opal/pouchdb/row"
else
  require "opal"
  require "opal/pouchdb/version"

  Opal.append_path File.expand_path('../..', __FILE__).untaint
end

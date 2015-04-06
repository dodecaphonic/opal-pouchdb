require "bundler"
Bundler.require

require "bundler/gem_tasks"
require "opal/rspec/rake_task"

require "yard"

Opal::RSpec::RakeTask.new(:default) do |s|
  s.index_path = "spec/pouchdb/index.html.erb"
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', "opal/**/*.rb"]   # optional
  t.options = ['--any', '--extra', '--opts']    # optional
  t.stats_options = ['--list-undoc']            # optional
end

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec,
               "integration:xlsx2yaml",
               "integration:xlsx2db",
               "integration:db2yaml"]

namespace :integration do
  desc "Run the xlsx2yaml pipeline (delegates to `make test-xlsx2yaml`)"
  task :xlsx2yaml do
    sh "make test-xlsx2yaml"
  end

  desc "Run the xlsx2db pipeline (delegates to `make test-xlsx2db`)"
  task :xlsx2db do
    sh "make test-xlsx2db"
  end

  desc "Run the db2yaml pipeline (delegates to `make test-db2yaml`)"
  task :db2yaml do
    sh "make test-db2yaml"
  end
end

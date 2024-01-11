Gem::Specification.new do |s|
  s.name        = "oracle_db_script_producer"
  s.version     = "1.0.0"
  s.summary     = "SQL script tool that can programmatically create create, insert, update, delete, trunc and similar queries for Oracle database."
  s.description = "SQL script tool that can programmatically create create, insert, update, delete, trunc and similar queries for Oracle database."
  s.authors     = ["tayak"]
  s.email       = "yasir.kiroglu@gmail.com"
  s.files       = ["lib/odsp.rb"]
  s.homepage    = "https://github.com/taiak/db_refresher"
  s.license     = "Apache-2.0"
  s.add_runtime_dependency 'ruby-oci8',     '~> 2.2.2'
end
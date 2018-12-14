require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

proj_dir = File.dirname(__FILE__)
$LOAD_PATH << "#{proj_dir}/lib"

task :mytest do
	require 'zombiehome'
end

task :console do
	load 'bin/console'
end

Rake::TestTask.new(:t1) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/zombiehome/dbFactory/dbFactory_test.rb"]
  # t.test_files = FileList["test/zombiehome/table/table_test.rb"]
end

task :t2 do
	
end

task :default => :test

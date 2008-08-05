require 'rake'
require 'rake/testtask'
require 'rcov/rcovtask'


task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << "tests"
  t.libs << "lib"
  t.test_files = FileList['tests/test_*.rb']
  t.verbose = true
end

desc 'Aggregate code coverage for tests'
task :coverage do
  Rcov::RcovTask.new("coverage") do |t|
    t.libs << "tests"
    t.libs << "lib"    
    t.test_files = FileList["tests/test_*.rb"]
    t.output_dir = "coverage"
    t.verbose = true
  end
end
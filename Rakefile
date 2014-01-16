require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs.push "spec", "test"
  t.test_files = FileList['spec/simperium/*_spec.rb']
  t.verbose    = true
end

Rake::TestTask.new('test:integration') do |t|
  t.libs       = %w(spec)
  t.test_files = FileList['spec/integration/*_spec.rb', 'test/test_*']
  t.verbose    = true
end

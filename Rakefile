require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs.push "spec", "test"
  t.test_files = FileList['spec/**/*_spec.rb', 'test/test_*']
  t.verbose = true
end

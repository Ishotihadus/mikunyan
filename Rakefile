# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/extensiontask'

task :scream do
  puts 'みくは自分を曲げないよ！'
end

task build: :compile

Rake::ExtensionTask.new('decoders/native') do |ext|
  ext.lib_dir = 'lib/mikunyan'
end

task default: %i[clobber compile spec]

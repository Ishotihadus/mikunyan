# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/extensiontask'

task :scream do
  puts 'みくは自分を曲げないよ！'
end

task build: :compile

%w[decoders/native decoders/crunch].each do |dir|
  Rake::ExtensionTask.new(dir) do |ext|
    ext.lib_dir = 'lib/mikunyan'
  end
end

task default: %i[clobber compile spec]

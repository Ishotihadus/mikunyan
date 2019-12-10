# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/extensiontask'

task :scream do
  puts 'みくは自分を曲げないよ！'
end

task build: :compile

ext_dirs = %w[decoders/native decoders/crunch]

ext_dirs.each do |dir|
  Rake::ExtensionTask.new(dir) do |ext|
    ext.lib_dir = 'lib/mikunyan'
  end
end

task compile: ext_dirs.map{|e| "compile:#{e}".to_sym}

task default: %i[clobber compile spec]

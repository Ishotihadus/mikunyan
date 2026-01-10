# frozen_string_literal: true

require 'extlz4'
require 'mikunyan'

def unlz4(bin)
  header = bin.unpack('V4')
  LZ4.raw_decode(bin.byteslice(16, header[2]))
end

exit(1) if ARGV.empty?

files = []
ARGV.each do |arg|
  if File.directory?(arg)
    files += Dir.glob("#{arg}/**/*")
  else
    files << arg
  end
end
files.select! {|e| File.file?(e)}

count = files.size
files.shuffle.each_with_index do |file, idx|
  type =
    File.open(file, 'rb') do |io|
      sig = io.read(5)
      next :raw if sig == 'Unity'

      sig = (sig + io.read(11)).unpack('V4')
      :cgss_lz4 if sig[0] == 100 && sig[3] == 1
    end
  next unless type

  print "\r\e[0K[#{idx + 1}/#{count}] #{file}"
  bundle =
    case type
    when :raw
      Mikunyan::AssetBundle.file(file)
    when :cgss_lz4
      Mikunyan::AssetBundle.load(unlz4(File.binread(file)))
    end
  bundle.each_asset do |asset|
    print "\r\e[0K[#{idx + 1}/#{count}] #{file}: #{asset.name}"
    asset.klasses.each do |klass|
      hash = klass.hash.unpack1('H*')
      next unless hash.size == 32 && klass.type_tree

      dir = "lib/mikunyan/typetrees/#{klass.class_id}"
      json_file = "#{dir}/#{hash}.json"
      next if File.exist?(json_file)

      puts "\r\e[0K[#{idx + 1}/#{count}] #{file}: #{asset.name}"
      puts "  #{klass.type_tree.tree.type} (#{klass.class_id}) -> #{hash}"
      Dir.mkdir(dir) unless File.directory?(dir)
      File.binwrite(json_file, JSON.generate(klass.type_tree.serialize))
    end
  end
end
puts

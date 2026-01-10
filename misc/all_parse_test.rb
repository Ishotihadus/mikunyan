# frozen_string_literal: true

require 'extlz4'
require 'mikunyan'

def unlz4(bin)
  header = bin.unpack('V4')
  LZ4.raw_decode(bin.byteslice(16, header[2]))
end

exit(1) if ARGV.empty?

files = []
opts = { recursive: false }
ARGV.each do |arg|
  if ['--recursive', '-r'].include?(arg)
    opts[:recursive] = true
  else
    files << arg
  end
end
files = files.flat_map do |f|
  if File.directory?(f)
    Dir.glob(opts[:recursive] ? "#{f}/**/*" : "#{f}/*")
  else
    f
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

  file_output = false
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
    asset_output = false
    asset.each_object do |obj|
      result = obj.parse
      unless result
        print "\r\e[0K"
        unless asset_output
          unless file_output
            puts file
            file_output = true
          end
          puts "  asset `#{asset.name}`"
          asset_output = true
        end
        puts "    \e[34m#{format('% 17x', obj.path_id)}: Skipped (#{obj.type})\e[0m"
      end
      # if obj.parse
      #   puts "    \e[32m#{format('% 17x', obj.path_id)}: Success\e[0m"
      # else
      #   puts "    \e[34m#{format('% 17x', obj.path_id)}: Skip (#{obj.type})\e[0m"
      # end
    rescue StandardError
      print "\r\e[0K"
      unless asset_output
        unless file_output
          puts file
          file_output = true
        end
        puts "  asset `#{asset.name}`"
        asset_output = true
      end
      puts "    \e[1m\e[31m#{format('% 17x', obj.path_id)}: Failed (#{$!})\e[0m"
      puts $!
    end
  end
end
puts

# mikunyan

Library to deserialize Unity AssetBundle files (\*.unity3d) and asset files.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mikunyan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mikunyan

If you want to install development build:

    $ git clone https://github.com/Ishotihadus/mikunyan
    $ cd mikunyan
    $ rake build
    $ gem install -l pkg/mikunyan-3.9.x.gem

## Usage

### Basic Usage

```ruby
require 'mikunyan'

# load AssetBundle
bundle = Mikunyan::AssetBundle.file(filename)

# you can load AssetBundle from blob
# bundle = Mikunyan::AssetBundle.load(blob)

# select asset (normaly only one asset)
asset = bundle.assets[0]

# or you can directly load asset
# asset = Mikunyan::Asset.file(filename)

# object list
list = asset.objects

# object PathIds
path_ids = asset.path_ids

# object container table (if available)
containers = asset.containers

# load object (Mikunyan::ObjectValue)
obj = asset.parse_object(path_ids[0])

# simplified structure (based on Hash)
obj_hash = asset.parse_object_simple(path_ids[0])

# hash can be easily serialized to json
require 'json'
obj_hash.to_json
```

### Mikunyan::ObjectValue

`Mikunyan::ObjectValue` can be 3 types. Value, array and map.

```ruby
# You can get whether obj is value or not
obj.value?

# get value
obj.value

# same as obj.value
obj[]


# You can get whether obj is array or not
obj.array?

# get array
obj.value

# you can directly access by index
obj[0]


# If obj is map, you can get keys
obj.keys

# get child object
obj[key]

# same as obj[key]
obj.key
```

### Unpack Texture2D

You can get png file directly from Texture2D asset. Output object's class is `ChunkyPNG::Image`.

Acceptable format is basic texture formats (1, 2, 3, 4, 5, 7 and 13) and ETC_RGB4 (34).

```ruby
require 'mikunyan/decoders'

# get some Texture2D asset
obj = asset.parse_object(path_ids[1])

# you can get Image object
img = Mikunyan::ImageDecoder.decode_object(obj)

# save it!
img.save('mikunyan.png')
```

### Json / YAML Outputer

`mikunyan-json` is an executable command for converting unity3d to json.

    $ mikunyan-json bundle.unity3d > bundle.json

Available options:

- `--as-asset` (`-a`): interpret input file as not AssetBudnle but Asset
- `--pretty` (`-p`): prettify output json (`mikunyan-json` only)
- `--yaml` (`-y`): YAML mode

## Dependencies

- [json](https://rubygems.org/gems/json)
- [extlz4](https://rubygems.org/gems/extlz4)
- [bin_utils](https://rubygems.org/gems/bin_utils)
- [chunky_png](https://rubygems.org/gems/chunky_png)

Mikunyan uses [oily_png](https://rubygems.org/gems/oily_png) instead of chunky_png if available.

## FAQ

### Sometimes unpacking fails

I'm sorry...

### Can I unpack Mesh files?

It's hard work for me...

### What mikunyan comes from?

[Miku Maekawa](http://www.project-imas.com/wiki/Miku_Maekawa).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ishotihadus/mikunyan.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

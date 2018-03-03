# mikunyan

A library to deserialize AssetBundle files (\*.unity3d) and asset files of Unity.

The name "Mikunyan" is derived from [Miku Maekawa](http://www.project-imas.com/wiki/Miku_Maekawa).

Ruby-Doc: http://www.rubydoc.info/gems/mikunyan/

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
    $ bundle install
    $ rake build
    $ gem install -l pkg/mikunyan-3.9.x.gem

## Usage

### Basic Usage

```ruby
require 'mikunyan'

# load an AssetBundle file
bundle = Mikunyan::AssetBundle.file(filename)

# you can also load a bundle from blob
# bundle = Mikunyan::AssetBundle.load(blob)

# select asset (a bundle normally contains only one asset)
asset = bundle.assets[0]

# or you can directly load an asset from an asset file
# asset = Mikunyan::Asset.file(filename)

# get a list of objects
list = asset.objects

# get PathIds of objects
path_ids = asset.path_ids

# get an container table of objects (if available)
containers = asset.containers

# load an object (Mikunyan::ObjectValue)
obj = asset.parse_object(path_ids[0])

# load an object to Ruby data structures
obj_hash = asset.parse_object_simple(path_ids[0])

# a Hash can be serialized to JSON
require 'json'
obj_hash.to_json
```

### Mikunyan::ObjectValue

`Mikunyan::ObjectValue` can be 3 types: value, array and key-value table.

```ruby
# get whether obj is value or not
obj.value?

# get a value
obj.value

# same as obj.value
obj[]


# get whether obj is array or not
obj.array?

# get an array
obj.value

# you can directly access by index
obj[0]


# get keys (if obj is key-value table)
obj.keys

# get child objects
obj[key]

# same as obj[key]
obj.key
```

### Unpack Texture2D

You can get image data directly from Texture2D object. Output object's class is `ChunkyPNG::Image`.

Some basic texture formats (1–5, 7, 9, 13–20, 22, 62, and 63), DXT1 (10), ETC_RGB4 (34), ETC2 (45, 47), and ASTC (48–59) are available.

```ruby
require 'mikunyan/decoders'

# get some Texture2D asset
obj = asset.parse_object(path_ids[1])

# you can get image data
img = Mikunyan::ImageDecoder.decode_object(obj)

# save it!
img.save('mikunyan.png')
```

Mikunyan cannot decode ASTC with HDR data. Use `Mikunyan::ImageDecoder.create_astc_file` instead.

### Json / YAML Outputter

`mikunyan-json` is an executable command for converting unity3d to JSON.

    $ mikunyan-json bundle.unity3d > bundle.json

Available options:

- `--as-asset` (`-a`): interpret input file as not AssetBundle but Asset
- `--pretty` (`-p`): prettify output JSON
- `--yaml` (`-y`): YAML mode

### Image Outputter

`mikunyan-image` is an executable command for unpacking images from unity3d.

    $ mikunyan-image bundle.unity3d

The console log is JSON data of output textures as follows.

```json
[
    {
        "name": "bg_b",
        "width": 1024,
        "height": 1024,
        "path_id": -744818715421265689
    },
    {
        "name": "bg_a",
        "width": 1024,
        "height": 1024,
        "path_id": 5562124901460497987
    }
]
```

If the option `--sprite` specified, `mikunyan-image` will output sprites. The logged JSON also contains sprite information.

```json
[
    {
        "name": "bg_a",
        "width": 1024,
        "height": 1024,
        "path_id": 5562124901460497987,
        "sprites": [
            {
                "name": "bg_a_0",
                "x": 1.0,
                "y": 303.0,
                "width": 1022.0,
                "height": 720.0,
                "path_id": -7546240288260780845
            },
            {
                "name": "bg_a_1",
                "x": 1.0,
                "y": 1.0,
                "width": 720.0,
                "height": 258.0,
                "path_id": -5293490190204738553
            }
        ]
    },
    {
        "name": "bg_b",
        "width": 1024,
        "height": 1024,
        "path_id": -744818715421265689,
        "sprites": [
            {
                "name": "bg_b_1",
                "x": 1.0,
                "y": 1.0,
                "width": 720.0,
                "height": 258.0,
                "path_id": 4884595733995530103
            },
            {
                "name": "bg_b_0",
                "x": 1.0,
                "y": 303.0,
                "width": 1022.0,
                "height": 720.0,
                "path_id": 7736251300187116441
            }
        ]
    }
]
```

Available options:

- `--as-asset` (`-a`): interpret input file as not AssetBundle but Asset
- `--outputdir` (`-o`): specify an output directory (default is a basename of input file without an extension)
- `--sprite` (`-s`): output sprites instead of textures
- `--pretty` (`-p`): prettify output JSON

## Dependencies

- [json](https://rubygems.org/gems/json)
- [extlz4](https://rubygems.org/gems/extlz4)
- [bin_utils](https://rubygems.org/gems/bin_utils)
- [chunky_png](https://rubygems.org/gems/chunky_png)

Mikunyan uses [oily_png](https://rubygems.org/gems/oily_png) instead of chunky_png if available.

## Implementation in other languages

- TypeScript: [shibunyan](https://github.com/AnemoneStar/shibunyan)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ishotihadus/mikunyan.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

# mikunyan

A Ruby library to deserialize AssetBundle files (\*.unity3d) and asset files of Unity.

The name “Mikunyan” is derived from [Miku Maekawa](http://www.project-imas.com/wiki/Miku_Maekawa).

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
objects = asset.objects

# get PathIds of objects
path_ids = asset.path_ids

# get an container table of objects (if available)
containers = asset.containers

# load an object (Mikunyan::ObjectValue)
obj = asset.parse_object(objects[0])

# load an object to Ruby data structures
obj_hash = asset.parse_object_simple(objects[0])

# a Hash can be serialized to JSON
require 'json'
obj_hash.to_json
```

### Mikunyan::ObjectValue

`Mikunyan::ObjectValue` is formed in 3 types: value, array, and key-value table.

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

Mikunyan generates `ChunkyPNG::Image` images directly from Texture2D objects.

Mikunyan can decode images in basic texture formats (1–5, 7, 9, 13–20, 22, 62, 63), DXT1 (10), DXT5 (12), PVRTC1 (30–33), ETC (34), EAC (41–44), ETC2 (45–47), ASTC (48–59), HDR ASTC (66–71), or Crunched format (28, 29, 64, 65).

```ruby
# get some Texture2D asset
obj = asset.parse_object(path_ids[1])

# you can get image data
img = obj.generate_png

# save it!
img.save('mikunyan.png')
```

### JSON / YAML Outputter

`mikunyan-json` is an executable command for converting unity3d to JSON.

    $ mikunyan-json bundle.unity3d > bundle.json

Available options:

- `--as-asset` (`-a`): interpret input file as not AssetBundle but Asset
- `--pretty` (`-p`): prettify output JSON
- `--yaml` (`-y`): YAML mode

### Image Outputter

`mikunyan-image` is an executable command for unpacking images from unity3d.

    $ mikunyan-image bundle.unity3d

The command generates JSON text, which contains information about unpacked images.

```json
[
  {
    "name": "bg_x",
    "width": 512,
    "height": 512,
    "format": 56,
    "path_id": -8556635666641176453
  },
  {
    "name": "bg",
    "width": 1024,
    "height": 1024,
    "format": 56,
    "path_id": -1848302546424191165
  }
]
```

If the option `--sprite` is specified, `mikunyan-image` will output sprites. The logged JSON also contains information about sprites.

```json
[
  {
    "name": "bg_x",
    "width": 512,
    "height": 512,
    "format": 56,
    "path_id": -8556635666641176453,
    "sprites": [
      {
        "name": "bg_4",
        "x": 171.0,
        "y": 1.0,
        "width": 168.0,
        "height": 510.0,
        "path_id": -9129589624490902606
      },
      {
        "name": "bg_5",
        "x": 341.0,
        "y": 45.0,
        "width": 168.0,
        "height": 210.0,
        "path_id": -4692216110975580946
      },
      {
        "name": "bg_2",
        "x": 1.0,
        "y": 1.0,
        "width": 168.0,
        "height": 510.0,
        "path_id": 5129117526830897711
      },
      {
        "name": "bg_3",
        "x": 341.0,
        "y": 301.0,
        "width": 168.0,
        "height": 210.0,
        "path_id": 8564534684796303817
      }
    ]
  },
  {
    "name": "bg",
    "width": 1024,
    "height": 1024,
    "format": 56,
    "path_id": -1848302546424191165,
    "sprites": [
      {
        "name": "bg_1",
        "x": 1.0,
        "y": 1.0,
        "width": 720.0,
        "height": 258.0,
        "path_id": -3411127056098763138
      },
      {
        "name": "bg_0",
        "x": 1.0,
        "y": 303.0,
        "width": 1022.0,
        "height": 720.0,
        "path_id": 7486118431221564872
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
- [extlzma2](https://rubygems.org/gems/extlzma2)
  - extlzma2 requires liblzma. You may need a `--with-liblzma-dir=` argument to install extlzma2.
- [bin_utils](https://rubygems.org/gems/bin_utils)
- [chunky_png](https://rubygems.org/gems/chunky_png)

Mikunyan uses [oily_png](https://rubygems.org/gems/oily_png) instead of chunky_png if available.

Note: extlz4 0.3 (current version) has a fatal bug because of LZ4 v1.9.0. In case of SIGSEGV in extlz4, you need to build extlz4 with the latest LZ4.

## Implementation in other languages

- TypeScript: [shibunyan](https://github.com/AnemoneStar/shibunyan)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ishotihadus/mikunyan.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgements

This project contains following softwares.

- [Unity's crunch/crnlib](https://github.com/Unity-Technologies/crunch) (zlib License)
- [FP16](https://github.com/Maratyszcza/FP16/) (MIT License)
- [endianness.h](https://gist.github.com/jtbr/7a43e6281e6cca353b33ee501421860c) (MIT License)

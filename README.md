# Lemur Flags

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     flags:
       github: willhbr/lemur
   ```

2. Run `shards install`

## Usage

```crystal
require "lemur"

Lemur.flag(my_flag, String, "A very important flag")

# Read ARGV and set all the flags
Lemur.init

puts Lemur.my_flag
```

Running the program:

```shell
$ ./my_program --my_flag="A very important value"
A very important value
```

## Contributing

1. Fork it (<https://github.com/willhbr/flags/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Will Richardson](https://github.com/willhbr) - creator and maintainer

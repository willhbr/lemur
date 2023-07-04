require "./parsers"

module Lemur
  FLAGS = [] of Lemur::FlagConfig
  @@args = [] of String

  def self.args
    @@args
  end

  class FlagException < Exception
  end

  module FlagConfig
    abstract def name : String
    abstract def on_flag(value : String)
    abstract def description : String
    abstract def finished
  end

  module ValueParsing(T)
    def from_flag(value : String)
      {% if T.union? %}
        {% for t in T.union_types %}
          {% unless t == Nil %}
            last_error = nil
            begin
              return {{ t }}.from_flag(value)
            rescue error
              last_error = error
            end
          {% end %}
        {% end %}
        {% if T.nilable? %}
          Nil.from_flag(value)
          return
        {% end %}
        if error = last_error
          raise last_error
        end
      {% else %}
        T.from_flag(value)
      {% end %}
    end
  end

  module SingleFlagConfig(T)
    include ValueParsing(T)
    @value : T? = nil
    @set = false

    def on_flag(value : String)
      if @set
        raise Lemur::FlagException.new "single flag --#{self.name} passed multiple times"
      end
      @set = true
      @value = from_flag(value)
    end

    def finished
      unless @set
        @value = self.default
      end
    end

    abstract def default : T

    def value : T
      @value || self.default
    end
  end

  module RepeatedFlagConfig(T)
    include ValueParsing(T)
    getter value = Array(T).new

    def on_flag(value : String)
      @value << from_flag(value)
    end

    def finished
    end
  end

  @@initialised = false

  def self.init
    return if @@initialised
    @@initialised = true
    flags_per_name = FLAGS.to_h { |f| {f.name, f} }
    args = [] of String
    failures = [] of Exception
    ARGV.each_with_index do |arg, index|
      if arg == "--"
        args.concat(ARGV[(index + 1)...])
        break
      end
      if arg.starts_with?("--") || arg.starts_with?('-')
        name, _, value = arg.partition('=')
        name = name.lchop?("--") || name.lchop('-')
        if flag = flags_per_name[name]?
          begin
            flag.on_flag(value)
          rescue ex : Lemur::FlagException
            failures << ex
          end
        else
          failures << Lemur::FlagException.new("unknown flag: #{name}")
        end
      end
    end
    FLAGS.each do |flag|
      begin
        flag.finished
      rescue ex : Lemur::FlagException
        failures << ex
      end
    end
    unless failures.empty?
      STDERR.puts failures.map(&.message).join('\n')
      exit 1
    end
    @@args = args
  end

  macro flag_internal(name, type, description, config, &block)
    {% begin %}
      class Lemur::Flag__{{ name }}%name
        include {{ config }}({{ type }})
        include Lemur::FlagConfig

        def name : String
          {{ name.stringify }}
        end

        def description : String
          {{ description }}
        end

        {{ block.body }}
      end

      module Lemur
        @@%flag = Lemur::Flag__{{ name }}%name.new
        FLAGS << @@%flag
        def self.{{ name }}
          @@%flag.value
        end
      end
    {% end %}
  end

  macro flag(name, type, description, default = nil)
    Lemur.flag_internal(
      {{ name }}, {{ type }}, {{ description }},
      Lemur::SingleFlagConfig) do
      def default : {{ type }}
        {% if default == nil && !type.resolve.nilable? %}
          raise Lemur::FlagException.new(
            "missing required flag: --#{self.name} (#{self.description})")
        {% else %}
          {{ default }}
        {% end %}
      end
    end
  end

  macro repeated_flag(name, type, description)
    Lemur.flag_internal(
      {{ name }}, {{ type }}, {{ description }},
      Lemur::RepeatedFlagConfig) do
    end
  end
end

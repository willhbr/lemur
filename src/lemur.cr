require "./parsers"

module Lemur
  FLAGS = {} of String => FlagSettable

  class FlagError < Exception
  end

  module FlagSettable
    abstract def set_from_value(value : String)
    abstract def is_set? : Bool
    abstract def set_to_default!
  end

  macro finished
    {% for name, flag in Lemur::FLAGS %}
      def self.{{ attr.id }}
        @@{{ attr }}.value
      end
    {% end %}
  end

  @@argv = [] of String
  @@initialized = false

  def self.init
    @@argv.clear
    errors = [] of Exception
    escape_found = false
    ARGV.each do |arg|
      if escape_found
        @@argv << arg
        next
      end
      if arg == "--"
        escape_found = true
        next
      end
      if arg.starts_with?("--") || arg.starts_with?('-')
        key, _, value = arg.partition('=')
        key = key.lchop?("--") || key.lchop('-')
        if flag = FLAGS[key]?
          begin
            flag.set_from_value(value)
          rescue error
            errors << error
          end
        else
          errors << FlagError.new("Got unknown flag --#{key}")
        end
      else
        @@argv.push(arg)
      end
    end
    FLAGS.each do |name, flag|
      unless flag.is_set?
        flag.set_to_default!
      end
      unless flag.is_set?
        errors << FlagError.new("No value passed for required flag #{flag}")
      end
    end
    if errors.any?
      errors.each do |err|
        puts err.message
      end
      raise FlagError.new("Lemur flag init failed.")
    end
    @@initialized = true
  end

  def self.check_initialized!
    unless @@initialized
      raise "Lemur was used but not initialized. Make sure to call Lemur.init before accessing flags."
    end
  end

  macro flag(name, type, default = nil)
    module Lemur
      @@{{ name }} = Flag({{ type }}).new(
        {{ name.stringify }},
        {% if default != nil %}
          Proc({{ type }}).new { {{ default }} }
        {% else %}
          nil
        {% end %})
      Lemur::FLAGS[{{ name.stringify }}] = @@{{ name }}
      def self.{{ name }}
        @@{{ name }}.value
      end
    end
  end
end

class Lemur::Flag(T)
  include FlagSettable

  @value : T?
  @set = false

  def initialize(@name : String, @default : Proc(T)?)
  end

  def set_from_value(value)
    {% if T.union? %}
      {% for t in T.union_types %}
        last_error = nil
        begin
          @value = {{ t }}.from_flag(value)
        rescue error
          last_error = error
        end
      {% end %}
      if error = last_error
        raise last_error
      end
    {% else %}
      @value = T.from_flag(value)
    {% end %}
    @set = true
  end

  def value : T
    Lemur.check_initialized!
    {% if T.nilable? %}
      @value
    {% else %}
      @value.not_nil!
    {% end %}
  end

  def is_set?
    @set
  end

  def set_to_default!
    {% begin %}
      if default = @default
        @set = true
        @value = default.call
      {% if T.nilable? %}
      else
        @set = true
        @value = nil
      {% end %}
      end
    {% end %}
  end

  def to_s(io)
    io << "--" << @name << ':' << T << "=" << @value
  end
end

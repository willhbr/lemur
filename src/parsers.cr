struct Bool
  def self.from_flag(value)
    case value
    when "true"
      true
    when "false"
      false
    else
      raise ArgumentError.new("Invalid boolean flag value: #{value}")
    end
  end
end

struct Int32
  def self.from_flag(value : String)
    value.to_i
  end
end

struct Int64
  def self.from_flag(value : String)
    value.to_i64
  end
end

class String
  def self.from_flag(value : String)
    value
  end
end

struct Nil
  def self.from_flag(value : String)
    nil
  end
end

struct Enum
  def self.from_flag(value : String)
    self.parse(value)
  end
end

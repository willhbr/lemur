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

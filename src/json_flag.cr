require "json"

struct Lemur::JSONFlag(T)
  getter wrapped

  def initialize(@wrapped : T)
  end

  def self.from_flag(value : String)
    new(T.from_json(value))
  end
end

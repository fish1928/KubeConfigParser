require 'ostruct'

class OpenStruct
  def self.to_os(hash)
    OpenStruct.new(hash.each_with_object({}) do |(key, val), memo|
      memo[key] = val.is_a?(Hash) ? to_os(val) : val
    end)
  end
end
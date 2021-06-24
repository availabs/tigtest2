class ByMonth < Partitioned::ByIntegerField
  self.abstract_class = true
  
  def self.partition_integer_field
    return :month
  end

  partitioned do |partition|
  end
  
end

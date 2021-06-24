class ByYear < Partitioned::ByIntegerField
  self.abstract_class = true
  
  def self.partition_integer_field
    return :year
  end

  partitioned do |partition|
  end

end

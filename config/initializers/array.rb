class Array

  # like #index, but uses include?, so can handle an array whose
  # elements may be arrays
  def index_with_sub v
    self.each_with_index do |a, i|
      if a.respond_to? :detect
        return i if a.detect {|elt| elt==v }
      else
        return i if a==v
      end
    end
    nil
  end

end
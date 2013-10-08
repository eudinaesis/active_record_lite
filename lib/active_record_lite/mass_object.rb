class MassObject
  def self.my_attr_accessible(*attributes)
    @attributes ||= []
    attributes.each do |attrib|
      @attributes << attrib unless @attributes.include?(attrib)
    end

    attributes.each do |ivar|
      self.send(:define_method, ivar) do
        instance_variable_get("@#{ivar}".to_sym)
      end
      self.send(:define_method, "#{ivar}=".to_sym) do |values|
        instance_variable_set("@#{ivar}".to_sym, values)
      end
    end
  end

  def self.get_attrs(*attributes)
    attributes.each do |ivar|
      self.send(:define_method, ivar) do
        instance_variable_get("@#{ivar}".to_sym)
      end
    end
  end

  def self.set_attrs(*attributes)
    @attributes ||= []
    attributes.each do |attrib|
      @attributes << attrib unless @attributes.include?(attrib)
    end

    attributes.each do |ivar|
      self.send(:define_method, "#{ivar}=".to_sym) do |values|
        instance_variable_set("@#{ivar}".to_sym, values)
      end
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(result_hash_array) # takes array of hashes, returns objs
    # debugger
    result_hash_array.map do |hash|
      self.new(hash)
    end
  end

  def initialize(params={}) # params is { attr_name => value } hash
    # debugger
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        self.send("#{attr_name}=".to_sym, value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end

end
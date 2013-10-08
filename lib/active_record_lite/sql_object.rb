class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name=self.name.pluralize.underscore)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    results = self::parse_all(rows)
  end

  def self.find(id)
    rows = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    self.new(rows.first)
  end

  def save
    @id.nil? ? create : update
  end

  private

  def attr_vals
    self.class.attributes.map do |attrib|
      instance_variable_get("@#{attrib}".to_sym)
    end
  end

  def create
    # debugger
    DBConnection.execute(<<-SQL, *attr_vals)
      INSERT INTO #{self.class.table_name}
        (#{self.class.attributes.join(", ")})
      VALUES
        (#{(["?"] * self.class.attributes.length).join(", ")})
    SQL
    @id = DBConnection.last_id
  end

  def update
    # debugger
    set_line = self.class.attributes.map do |attrib|
      "#{attrib} = ?"
    end.join(", ")
    DBConnection.execute(<<-SQL, *attr_vals)
      UPDATE #{self.class.table_name}
      SET #{set_line}
      WHERE id = #{attr_vals[0]}
    SQL
    # true
  end
end


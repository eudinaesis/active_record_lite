class Relation < SQLObject
  attr_accessor :where_clauses, :where_values

  def self.all
    rows = DBConnection.execute(<<-SQL, *where_vlues)
      SELECT *
      FROM #{table_name}
      WHERE #{where_clauses}
    SQL
    results = self::parse_all(rows)
  end

  def initialize
    @where_clauses = []
    @where_values = []
  end
end
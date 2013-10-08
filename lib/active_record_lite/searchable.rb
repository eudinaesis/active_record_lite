module Searchable
  def where(params) # takes hash of col name => vals
    where_clause = params.keys.map do |col_name|
      "#{col_name} = ?"
    end.join(" AND ")
    # debugger
    rows = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{table_name}
      WHERE #{where_clause}
    SQL
    results = self::parse_all(rows)
  end

end
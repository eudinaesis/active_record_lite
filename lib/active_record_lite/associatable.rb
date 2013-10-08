require 'active_support/inflector'

module Associatable
  class AssocParams
    def initialize(association_name, settings={})
      @association_name = association_name
      @settings = settings
    end

    def other_class_name
      if @settings[:class_name].nil?
        @association_name.to_s.camelcase.to_sym
      else
        @settings[:class_name].to_sym
      end
    end

    def primary_key
      if @settings[:primary_key].nil?
        "id"
      else
        @settings[:primary_key].to_s
      end
    end

    def foreign_key
      if @settings[:foreign_key].nil?
        @association_name.to_s.underscore + "_id"
      else
        @settings[:foreign_key].to_s
      end
    end

    def other_class
      other_class_name.to_s.constantize
    end

    def other_table_name
      other_class.table_name
    end
  end

  class BelongsToAssocParams < AssocParams
  end

  class HasManyAssocParams < AssocParams
    def initialize(association_name, own_class_name, settings={})
      super(association_name, settings)
      @own_class_name = own_class_name
    end

    def other_class_name
      super.to_s.singularize.to_sym
    end

    def foreign_key
      if @settings[:foreign_key].nil?
        @own_class_name.underscore + "_id"
      else
        @settings[:foreign_key].to_s
      end
    end
  end

  def assoc_params(assoc_name)
    @assoc_params[assoc_name]
  end

  def belongs_to(association_name, settings={})
    aps = BelongsToAssocParams.new(association_name, settings)
    # debugger
    @assoc_params ||= {}
    @assoc_params[association_name] = aps
    define_method(association_name) do
      aps.other_class.where({
          aps.primary_key => instance_variable_get("@#{aps.foreign_key}".to_sym)
        }).first
      # rows = DBConnection.execute(<<-SQL, instance_variable_get("@#{aps.foreign_key}".to_sym))
      #   SELECT *
      #   FROM #{aps.other_table_name}
      #   WHERE #{aps.primary_key} = ?
      # SQL
      # aps.other_class::parse_all(rows).first
    end
  end

  def has_many(association_name, settings={})
    aps = HasManyAssocParams.new(association_name, name, settings)
    @assoc_params ||= {}
    @assoc_params[association_name] = aps
    define_method(association_name) do
      aps.other_class.where({
          aps.foreign_key => instance_variable_get("@#{aps.primary_key}".to_sym)
        })

      # rows = DBConnection.execute(<<-SQL, instance_variable_get("@#{aps.primary_key}".to_sym))
      #   SELECT *
      #   FROM #{aps.other_table_name}
      #   WHERE #{aps.foreign_key} = ?
      # SQL
      # aps.other_class::parse_all(rows)
    end
  end

  def has_one_through(association_name, source_name)
    # source_assoc = assoc_params(source_name)
    # result_assoc = source_assoc.other_class.assoc_params(association_name)
    # source_table = source_assoc.other_table_name
    # result_table = result_assoc.other_table_name
    define_method(association_name) do
      source_assoc = self.class.assoc_params(source_name)
      result_assoc = source_assoc.other_class.assoc_params(association_name)
      source_table = source_assoc.other_table_name
      result_table = result_assoc.other_table_name

      # sql_hash = {
      #   :result_table => result_table,
      #   :source_table => source_table,
      #   :result_primary_key => "#{result_table}.#{result_assoc.primary_key}",
      #   :source_foreign_key => "#{source_table}.#{result_assoc.foreign_key}",
      #   :source_primary_key => "#{source_table}.#{source_assoc.primary_key}",
      #   :own_foreign_key => "#{instance_variable_get("@#{source_assoc.foreign_key}".to_sym)}"
      # }

      # result = DBConnection.execute(<<-SQL, sql_hash)
      #   SELECT :result_table.*
      #   FROM :result_table JOIN :source_table
      #     ON :result_primary_key = :source_foreign_key
      #   WHERE :source_primary_key = :own_foreign_key
      # SQL

      own_fkey = instance_variable_get("@#{source_assoc.foreign_key}".to_sym)

      result = DBConnection.execute(<<-SQL, own_fkey)
        SELECT #{result_table}.*
        FROM #{result_table} JOIN #{source_table}
          ON #{result_table}.#{result_assoc.primary_key}
            = #{source_table}.#{result_assoc.foreign_key}
        WHERE #{source_table}.#{source_assoc.primary_key}
            = ?
      SQL
      result_assoc.other_class::parse_all(result).first
    end
  end
end
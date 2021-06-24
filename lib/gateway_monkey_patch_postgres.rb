# Patch for /gems/partitioned-1.3.4/lib/monkey_patch_postgres.rb
# replaced @columns with self.columns
require 'active_record'
require 'active_record/base'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/postgresql_adapter'

#
# Patching {ActiveRecord::ConnectionAdapters::TableDefinition} and
# {ActiveRecord::ConnectionAdapters::PostgreSQLAdapter} to add functionality
# needed to abstract partition specific SQL statements.
#
module ActiveRecord::ConnectionAdapters
  #
  # Patches associated with building check constraints.
  #
  class TableDefinition
    #
    # Builds a SQL check constraint
    #
    # @param [String] constraint a SQL constraint
    def check_constraint(constraint)
      self.columns << Struct.new(:to_sql).new("CHECK (#{constraint})")
    end
  end
end

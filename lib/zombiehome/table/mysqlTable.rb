require_relative 'table'
module Zombiehome

	class MysqlDBFactory
		class Table < DBFactory::Table
			def refresh_columns_info
				@columns = []
				@primary_key_name_list = []
				column_name_symbols = []

				@db.select_and_handle(%Q{
					SELECT
						*
					FROM
						information_schema.columns
					WHERE
						table_name = '#{@table_name}'
				}) do |r|
					col = Column.new
					Column.members.each do |column_info_field|
						column_info_field_upper = column_info_field.to_s.upcase
						col[column_info_field] = r[column_info_field_upper] || "(null)"

					end
					@columns << col

					column_name_symbols << col.column_name.to_sym
				end

				# Record the primary key of the table.
				@columns.each do |col_info|
					if col_info.column_key == "PRI"
						@primary_key_name_list << col_info.column_name
					end
				end

				# Create a Struct instance that is used to create a new record object
				@inst_struct = Struct.new(*column_name_symbols)
				@inst_struct.class_eval do
					def <<(h)
						h.each_entry do |k, v|
							self[k.to_sym] = v if self.members.include?(k.to_sym)
						end
					end
				end
			end
		end
	end
end